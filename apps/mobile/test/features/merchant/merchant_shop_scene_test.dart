import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/merchant/presentation/screens/merchant_mode_exit_screen.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/merchant_shop_scene.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_coins.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_token.dart';
import 'package:mooze_mobile/themes/motion.dart';

import '../../shared/test_app.dart';
import '../../shared/widgets/motion/motion_test_helpers.dart';

void main() {
  const light = 'HapticFeedbackType.lightImpact';
  late List<String> haptics;

  void recordHaptics(WidgetTester tester) {
    haptics = [];
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        haptics.add(call.arguments as String);
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
  }

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpScene(WidgetTester tester, double time, {double tap = 0}) {
    phone(tester);
    return tester.pumpWidget(
      wrapForTest(
        Scaffold(
          body: Center(
            child: MerchantShopScene(time: time, tap: tap),
          ),
        ),
      ),
    );
  }

  /// How lit the window and the door of the shop are.
  double lights(WidgetTester tester) => tester
      .widget<Opacity>(
        find
            .ancestor(
              of: find.byWidgetPredicate(
                (w) =>
                    w is SvgPicture &&
                    w.bytesLoader is SvgAssetLoader &&
                    (w.bytesLoader as SvgAssetLoader).assetName ==
                        merchantShopLightsGlyph,
              ),
              matching: find.byType(Opacity),
            )
            // The nearest: the one of the lights.
            .first,
      )
      .opacity;

  Finder payments() => find.byWidgetPredicate(
    (w) => w is GlyphToken && w.glyphPath == stagePixGlyph,
  );

  /// The shop: the one token that is no Pix payment.
  Finder shop() => find.byWidgetPredicate(
    (w) => w is StageToken && w.shape is RoundedRectangleBorder,
  );

  /// The opacity each Pix payment shows with.
  List<double> paymentOpacities(WidgetTester tester) => [
    for (final element in payments().evaluate())
      tester
          .widget<Opacity>(
            find
                .ancestor(
                  of: find.byWidget(element.widget),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity,
  ];

  group('the glyphs of the shop', () {
    Future<String> load(String path) => rootBundle.loadString(path);
    Set<String> colorsOf(String svg) => RegExp(
      '#[0-9A-Fa-f]{6}',
    ).allMatches(svg).map((m) => m[0]!.toUpperCase()).toSet();
    Set<String> pathsOf(String svg) =>
        RegExp(r'd="([^"]+)"').allMatches(svg).map((m) => m[1]!).toSet();

    test('keep to the two tones, and the lights are all lit', () async {
      expect(colorsOf(await load(merchantShopGlyph)), {'#FFFFFF', '#8E8E93'});
      expect(colorsOf(await load(merchantShopLightsGlyph)), {'#FFFFFF'});
    });

    test(
      'the lights lie exactly on the window and the door of the shop',
      () async {
        final lights = pathsOf(await load(merchantShopLightsGlyph));
        expect(lights, hasLength(2));
        expect(pathsOf(await load(merchantShopGlyph)), containsAll(lights));
      },
    );
  });

  group('the scene', () {
    testWidgets('the lights of the shop turn on at the peak, and stay on', (
      tester,
    ) async {
      const on = MerchantShopScene.lightsOn;
      await pumpScene(tester, MerchantShopScene.atEntrance(on - 0.05));
      expect(lights(tester), 0);
      await pumpScene(tester, MerchantShopScene.atEntrance(on + 0.15));
      expect(lights(tester), 1);
      await pumpScene(tester, 1);
      expect(lights(tester), 1);
    });

    testWidgets('the payments come in after the lights, and rest beside the '
        'shop, none in front of it', (tester) async {
      await pumpScene(
        tester,
        MerchantShopScene.atEntrance(MerchantShopScene.lightsOn),
      );
      expect(paymentOpacities(tester), everyElement(0));

      await pumpScene(tester, 1);
      expect(payments(), findsNWidgets(MerchantShopScene.payments));
      expect(paymentOpacities(tester), everyElement(greaterThan(0.5)));
      final rect = tester.getRect(shop());
      for (final element in payments().evaluate()) {
        final at = tester.getCenter(find.byWidget(element.widget));
        expect((at.dx - rect.center.dx).abs(), greaterThan(rect.width / 2));
      }
    });

    testWidgets('a tap turns the shop once: its lights go off as it turns, '
        'and turn on again', (tester) async {
      double yaw() => tester.widget<StageToken>(shop()).yaw;
      await pumpScene(tester, 1);
      final rest = yaw();

      // A quarter of the way, it has turned on.
      await pumpScene(tester, 1, tap: MerchantShopScene.tapLightsOn / 4);
      expect((yaw() - rest).abs(), greaterThan(0.3));
      // Halfway, edge-on past its back, its lights are off.
      await pumpScene(tester, 1, tap: MerchantShopScene.tapLightsOn / 2);
      expect(lights(tester), lessThan(0.05));

      await pumpScene(tester, 1, tap: 1);
      expect(lights(tester), 1);
      expect(yaw(), closeTo(rest, 1e-9));
    });
  });

  group('the exit screen', () {
    Future<void> pumpExit(WidgetTester tester) async {
      phone(tester);
      recordHaptics(tester);
      await tester.pumpWidget(
        ProviderScope(child: wrapForTest(const MerchantModeExitScreen())),
      );
    }

    /// Milliseconds from the start of the scene to [time] of it.
    Duration at(double time) => Duration(
      microseconds: (time * MerchantShopScene.duration.inMicroseconds).round(),
    );

    final lightsOnAt = at(
      MerchantShopScene.atEntrance(MerchantShopScene.lightsOn),
    );

    double opacityOf(WidgetTester tester, String text) => tester
        .widget<FadeTransition>(
          find
              .ancestor(
                of: find.text(text),
                matching: find.byType(FadeTransition),
              )
              .first,
        )
        .opacity
        .value;

    testWidgets('one light haptic as the lights turn on, and the question '
        'waits for them', (tester) async {
      await pumpExit(tester);
      await tester.pump();
      await tester.pump(lightsOnAt - const Duration(milliseconds: 40));
      expect(haptics, isEmpty);
      expect(opacityOf(tester, 'Pronto para vender?'), 0);
      expect(opacityOf(tester, 'Receber novo pagamento'), 0);

      await tester.pump(const Duration(milliseconds: 80));
      expect(haptics, [light]);
      await tester.pump(const Duration(milliseconds: 120));
      expect(opacityOf(tester, 'Pronto para vender?'), greaterThan(0));

      await tester.pumpAndSettle();
      expect(haptics, [light]);
      expect(opacityOf(tester, 'Pronto para vender?'), 1);
      expect(opacityOf(tester, 'Receber novo pagamento'), 1);
    });

    testWidgets('the scene rests after its timeline', (tester) async {
      await pumpExit(tester);
      await tester.pump();
      await tester.pump(MerchantShopScene.duration);
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('a tap on the shop turns it once, with one light haptic as '
        'its lights turn on again; a tap while it turns does nothing', (
      tester,
    ) async {
      await pumpExit(tester);
      await tester.pumpAndSettle();
      haptics.clear();

      final scene = find.byType(MerchantShopScene);
      await tester.tap(scene);
      await tester.pump();
      await tester.pump(Durations.short3);
      expect(haptics, isEmpty);
      await tester.tap(scene);
      // The turn goes on from where it was, and ends on time.
      await tester.pump(Motion.durationShopTap - Durations.short3);
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(haptics, [light]);

      // Done: the next tap turns it again.
      await tester.tap(scene);
      await tester.pumpAndSettle();
      expect(haptics, [light, light]);
    });

    testWidgets('with reduced motion, the shop opens at once, without a '
        'haptic, and a tap only answers with one', (tester) async {
      reduceMotion(tester);
      await pumpExit(tester);
      await tester.pump();
      expect(lights(tester), 1);
      expect(opacityOf(tester, 'Pronto para vender?'), 1);
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(haptics, isEmpty);

      await tester.tap(find.byType(MerchantShopScene));
      await tester.pump();
      expect(haptics, [light]);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });
}
