import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/first_access/first_access.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/first_access/providers/terms_acceptance_provider.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/first_access/widgets/first_access_scene.dart';
import 'package:mooze_mobile/shared/analytics/analytics.dart';
import 'package:mooze_mobile/shared/analytics/providers.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/stage/glyph_colors.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_coins.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/widgets/motion/motion_test_helpers.dart';
import 'setup_test_app.dart';

class _MemoryConsent implements ConsentStore {
  bool value = false;

  @override
  bool read() => value;

  @override
  Future<void> write(bool enabled) async => value = enabled;
}

void main() {
  late OpenedRoutes opened;
  late SharedPreferences prefs;

  setUp(() async {
    opened = OpenedRoutes();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> open(
    WidgetTester tester, {
    bool analyticsConfigured = false,
    bool termsAccepted = false,
    double textScale = 1,
    bool pumpEntrance = true,
  }) async {
    usePhoneSize(tester);
    final router = GoRouter(
      initialLocation: '/setup/first-access',
      routes: [
        GoRoute(
          path: '/setup/first-access',
          builder: (_, _) => const FirstAccessScreen(),
        ),
        opened.stub('/setup/create-wallet/configure-seeds'),
        opened.stub('/setup/import-wallet'),
      ],
    );
    await tester.pumpWidget(
      setupTestApp(
        router: router,
        textScale: textScale,
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          if (termsAccepted)
            termsAcceptanceProvider.overrideWith((ref) => true),
          if (analyticsConfigured)
            analyticsProvider.overrideWith(
              (ref) => AnalyticsController(
                configured: true,
                store: _MemoryConsent(),
                load: (_) async => throw UnimplementedError(),
              ),
            ),
        ],
      ),
    );
    if (pumpEntrance) await settle(tester);
  }

  bool createEnabled(WidgetTester tester) =>
      tester.widget<PrimaryButton>(find.byType(PrimaryButton)).isEnabled;

  bool importEnabled(WidgetTester tester) =>
      tester
          .widget<TextButton>(
            find.ancestor(
              of: find.text('Importar carteira'),
              matching: find.byType(TextButton),
            ),
          )
          .onPressed !=
      null;

  testWidgets('both ways in wait for the terms', (tester) async {
    await open(tester);

    expect(createEnabled(tester), isFalse);
    expect(importEnabled(tester), isFalse);

    await tester.tap(find.byType(Checkbox));
    await settle(tester);

    expect(createEnabled(tester), isTrue);
    expect(importEnabled(tester), isTrue);
  });

  testWidgets('create opens the phrase length step', (tester) async {
    await open(tester);
    await tester.tap(find.byType(Checkbox));
    await settle(tester);

    await tester.tap(find.text('Criar Carteira'));
    await settle(tester);

    expect(opened.last, '/setup/create-wallet/configure-seeds');
  });

  testWidgets('import opens the import screen', (tester) async {
    await open(tester);
    await tester.tap(find.byType(Checkbox));
    await settle(tester);

    await tester.tap(find.text('Importar carteira'));
    await settle(tester);

    expect(opened.last, '/setup/import-wallet');
  });

  testWidgets('sits on the screen backdrop, with the terms and analytics', (
    tester,
  ) async {
    await open(tester, analyticsConfigured: true);

    expect(find.byType(AppBackdrop), findsWidgets);
    expect(find.byType(Checkbox), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('fits a phone at 200% text', (tester) async {
    await open(tester, analyticsConfigured: true, textScale: 2);

    expect(tester.takeException(), isNull);
    expect(find.text('Criar Carteira'), findsOneWidget);
  });

  group('the door', () {
    const knock = 'HapticFeedbackType.mediumImpact';
    const tap = 'HapticFeedbackType.lightImpact';
    late List<Object?> haptics;

    setUp(() => haptics = []);

    void recordHaptics(WidgetTester tester) {
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments);
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
    }

    DoorMotion motion(WidgetTester tester) => tester
        .widget<FirstAccessSceneView>(find.byType(FirstAccessSceneView))
        .motion;

    /// The coins of the assets that come out of the doorway.
    final coins = find.byType(AssetCoin);

    /// Pumps 16 ms frames for [duration], as a device does: a clock started
    /// on a frame, as the assets at the peak, runs from the next one.
    Future<void> frames(WidgetTester tester, Duration duration) async {
      const frame = Duration(milliseconds: 16);
      for (var t = Duration.zero; t < duration; t += frame) {
        await tester.pump(frame);
      }
    }

    /// Taps the terms and lets the door start on the next frame.
    Future<void> toggleTerms(WidgetTester tester) async {
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.pump();
    }

    for (final (name, screen) in const [
      ('a common phone', Size(390, 844)),
      ('an Android phone', Size(360, 800)),
      ('a small phone', Size(375, 667)),
      ('a narrow phone', Size(320, 568)),
    ]) {
      testWidgets('on $name, the assets stay within the screen as they come '
          'out and sway both ways', (tester) async {
        await open(tester);
        tester.view.physicalSize = screen * 3;
        await tester.pump();

        await toggleTerms(tester);
        const step = Duration(milliseconds: 48);
        for (
          var t = Duration.zero;
          t < Motion.durationAmbient * 4.6;
          t += step
        ) {
          await tester.pump(step);
          for (final coin in tester.widgetList(coins)) {
            final rect = tester.getRect(find.byWidget(coin));
            expect(rect.left, greaterThanOrEqualTo(0), reason: '$t');
            expect(rect.right, lessThanOrEqualTo(screen.width), reason: '$t');
          }
        }
        expect(coins, findsNWidgets(Asset.values.length));
      });
    }

    testWidgets('its face bears the Mooze wordmark', (tester) async {
      await open(tester);

      Finder svg(String asset) => find.descendant(
        of: find.byType(FirstAccessSceneView),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is SvgPicture &&
              widget.bytesLoader is SvgAssetLoader &&
              (widget.bytesLoader as SvgAssetLoader).assetName == asset,
        ),
      );
      expect(svg('assets/logos/logo_primary.svg'), findsWidgets);
      expect(svg('assets/images/onboarding/mooze_m.svg'), findsNothing);
    });

    testWidgets('takes the place of the app image, enters, and rests shut '
        'within 5 s', (tester) async {
      await open(tester);

      expect(find.byType(FirstAccessScene), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(motion(tester).time, inExclusiveRange(0, 1));
      expect(motion(tester).open, 0);

      await tester.pump(Motion.durationAmbient * 2);
      await tester.pump(const Duration(milliseconds: 16));
      expect(motion(tester).time, 1);
      expect(motion(tester).open, 0);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('opens when the terms are accepted, with a knock at its '
        'peak, and shuts with a tap when they are not', (tester) async {
      recordHaptics(tester);
      await open(tester);

      await toggleTerms(tester);
      expect(motion(tester).opening, isTrue);
      await tester.pump(Motion.durationDoorOpen * (DoorMotion.peak * 0.8));
      expect(motion(tester).open, inExclusiveRange(0, DoorMotion.peak));
      expect(haptics, isEmpty);
      await tester.pump(Motion.durationDoorOpen);
      expect(motion(tester).open, 1);
      expect(haptics, [knock]);

      await toggleTerms(tester);
      expect(motion(tester).opening, isFalse);
      await tester.pump(Motion.durationSlow * 0.5);
      expect(motion(tester).open, inExclusiveRange(0, 1));
      expect(haptics, [knock]);
      await tester.pump(Motion.durationSlow);
      expect(motion(tester).open, 0);
      expect(haptics, [knock, tap]);
      // The assets are in, and their clock waits for the next opening:
      // once the screen has settled, nothing moves.
      expect(coins, findsNothing);
      expect(motion(tester).orbit, 0);
      await tester.pump(Motion.durationAmbient * 2);
      expect(motion(tester).orbit, 0);
      expect(tester.binding.hasScheduledFrame, isFalse);

      // Opened again, the assets come out again.
      await toggleTerms(tester);
      await frames(tester, Motion.durationDoorOpen * 0.6);
      expect(haptics, [knock, tap, knock]);
      expect(motion(tester).orbit, inExclusiveRange(0, 0.1));
    });

    testWidgets('shut before its peak, it opens again with its knock; shut '
        'after it, it opens again without a second knock', (tester) async {
      recordHaptics(tester);
      await open(tester);

      await toggleTerms(tester);
      await tester.pump(Motion.durationDoorOpen * (DoorMotion.peak * 0.5));
      await toggleTerms(tester);
      await toggleTerms(tester);
      await frames(tester, Motion.durationDoorOpen);
      expect(haptics, [knock]);

      // Back from open to just past the peak, and open again.
      await toggleTerms(tester);
      await frames(tester, Motion.durationSlow * 0.3);
      expect(motion(tester).open, greaterThan(DoorMotion.peak));
      await toggleTerms(tester);
      await frames(tester, Motion.durationDoorOpen);
      expect(motion(tester).open, 1);
      expect(haptics, [knock]);
      // The assets go on from where they were.
      expect(motion(tester).orbit, greaterThan(0.35));
    });

    testWidgets('as it opens, the assets come out of the doorway in their '
        'own colors, around the Mooze coin, and sway back and forth for as '
        'long as it stays open', (tester) async {
      await open(tester);
      expect(coins, findsNothing);

      await toggleTerms(tester);
      await tester.pump(Motion.durationDoorOpen * (DoorMotion.peak * 0.8));
      expect(coins, findsNothing);

      // Past the peak.
      await frames(tester, Motion.durationDoorOpen * 0.3);
      expect(motion(tester).orbit, inExclusiveRange(0, 0.1));
      expect(
        tester.widgetList<AssetCoin>(coins).map((coin) => coin.asset),
        unorderedEquals(Asset.values),
      );
      for (final coin in tester.widgetList<AssetCoin>(coins)) {
        expect(
          coin.palette.base,
          CoinGlyphColors.colorOf(coin.asset),
          reason: '${coin.asset}',
        );
      }
      expect(
        find.descendant(
          of: find.byType(FirstAccessSceneView),
          matching: find.byType(GlyphToken),
        ),
        findsOneWidget,
      );

      // Out: then one way, back, the other way, and on.
      final sways = <double>[];
      for (var i = 0; i < 24; i++) {
        await tester.pump(Motion.durationAmbient * 0.5);
        sways.add(motion(tester).sway);
      }
      expect(motion(tester).arrival, 1);
      expect(sways.reduce(math.max), greaterThan(0.9));
      expect(sways.reduce(math.min), lessThan(-0.9));
      expect(sways.sublist(12).reduce(math.max), greaterThan(0.9));
      expect(tester.binding.hasScheduledFrame, isTrue);
    });

    testWidgets('once the door rests, the assets sway without painting the '
        'door again', (tester) async {
      await open(tester, termsAccepted: true);
      await tester.pump(Motion.durationAmbient * 2);

      /// The layer that [of] paints on.
      RenderRepaintBoundary layerOf(Finder of) =>
          tester.renderObject<RenderRepaintBoundary>(
            find.ancestor(of: of, matching: find.byType(RepaintBoundary)).first,
          );
      Finder painting(String painter) => find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint &&
            widget.painter.runtimeType.toString() == painter,
      );
      final door = [
        layerOf(painting('_BackPainter')),
        layerOf(painting('_DoorLightPainter')),
      ];
      final assets = layerOf(coins.first);
      // A layer painted again records new pictures; the layers that move or
      // clip what it paints may stay.
      List<PictureLayer> pictures(List<RenderRepaintBoundary> layers) {
        final found = <PictureLayer>[];
        void visit(Layer? first) {
          for (Layer? layer = first; layer != null; layer = layer.nextSibling) {
            if (layer is PictureLayer) found.add(layer);
            if (layer is ContainerLayer) visit(layer.firstChild);
          }
        }

        for (final layer in layers) {
          visit(layer.debugLayer!.firstChild);
        }
        return found;
      }

      final doorBefore = pictures(door);
      final assetsBefore = pictures([assets]);

      final sway = motion(tester).sway;
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(motion(tester).sway, isNot(sway));
      expect(pictures([assets]), isNot(assetsBefore));
      expect(pictures(door), doorBefore);
    });

    testWidgets('stays open, quietly, when the screen shows again with the '
        'terms accepted', (tester) async {
      recordHaptics(tester);
      await open(tester, termsAccepted: true);

      expect(motion(tester).open, 1);
      expect(motion(tester).arrival, 1);
      final sway = motion(tester).sway;
      await tester.pump(Motion.durationAmbient * 0.5);
      expect(motion(tester).sway, isNot(sway));
      expect(motion(tester).arrival, 1);
      expect(haptics, isEmpty);
    });

    testWidgets('under reduced motion, rests at once, and opens and shuts at '
        'once with a light tap', (tester) async {
      reduceMotion(tester);
      recordHaptics(tester);
      await open(tester, pumpEntrance: false);

      // On the first frame.
      expect(motion(tester).time, 1);
      expect(motion(tester).open, 0);
      await settle(tester);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(motion(tester).open, 1);
      expect(motion(tester).orbit, 1);
      expect(haptics, [tap]);
      // The assets rest: once the checkbox has settled, nothing moves.
      await tester.pump(const Duration(seconds: 1));
      expect(motion(tester).orbit, 1);
      expect(tester.binding.hasScheduledFrame, isFalse);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(motion(tester).open, 0);
      expect(haptics, [tap, tap]);
      // Once the checkbox has settled, nothing moves.
      await tester.pump(const Duration(seconds: 1));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    test('the flash, the shockwave, and the sparkles leave at the peak, only '
        'on the way in: the door shuts quietly', () {
      const before = DoorMotion(open: DoorMotion.peak - 0.01);
      const after = DoorMotion(open: DoorMotion.peak + 0.1);
      const shutting = DoorMotion(open: DoorMotion.peak + 0.1, opening: false);

      expect(before.flash, isNull);
      expect(after.flash, inExclusiveRange(0, 1));
      expect(shutting.flash, isNull);

      expect(before.shockwave, 0);
      expect(after.shockwave, inExclusiveRange(0, 1));
      expect(shutting.shockwave, 0);

      expect(const DoorMotion(open: 0.7).sparkle, 0.7);
      expect(const DoorMotion(open: 0.7, opening: false).sparkle, 0);
    });

    test('the assets arrive over the entrance of an onboarding scene, then '
        'sway one way, back, and the other way', () {
      final arrival =
          Motion.durationOnboardingScene.inMicroseconds /
          (Motion.durationAmbient * 2).inMicroseconds;
      expect(const DoorMotion(orbit: 0).arrival, 0);
      expect(DoorMotion(orbit: arrival / 2).arrival, 0.5);
      expect(DoorMotion(orbit: arrival).arrival, 1);
      expect(const DoorMotion(orbit: 7.3).arrival, 1);

      expect(const DoorMotion(orbit: 0).sway, 0);
      expect(const DoorMotion(orbit: 0.5).sway, closeTo(1, 1e-9));
      expect(const DoorMotion(orbit: 1).sway, closeTo(0, 1e-9));
      expect(const DoorMotion(orbit: 1.5).sway, closeTo(-1, 1e-9));
      expect(const DoorMotion(orbit: 2.5).sway, closeTo(1, 1e-9));
    });

    test('the door swings from ajar to open, and the assets come out from '
        'the peak, and go back in as it shuts', () {
      expect(const DoorMotion().swing, 0);
      expect(const DoorMotion(open: 0.3).swing, inExclusiveRange(0, 1));
      expect(const DoorMotion(open: 1).swing, 1);

      expect(const DoorMotion(open: DoorMotion.peak).presence, 0);
      expect(const DoorMotion(open: 0.7).presence, inExclusiveRange(0, 1));
      expect(const DoorMotion(open: 1).presence, 1);
      expect(
        const DoorMotion(open: 0.7, opening: false).presence,
        const DoorMotion(open: 0.7).presence,
      );
    });

    testWidgets('paints in both themes, at every moment, in any room', (
      tester,
    ) async {
      for (final theme in [AppTheme.darkTheme, AppTheme.lightTheme]) {
        for (final size in const [
          Size(350, 320),
          Size(300, 90),
          Size(350, 0),
          Size.zero,
        ]) {
          for (final motion in const [
            DoorMotion(time: 0),
            DoorMotion(time: 0.1),
            DoorMotion(time: 0.5),
            DoorMotion(open: 0.4, orbit: 0),
            DoorMotion(open: 0.7, orbit: 0.1),
            DoorMotion(open: 1),
            DoorMotion(open: 0.5, opening: false),
          ]) {
            await tester.pumpWidget(
              MaterialApp(
                builder: (context, child) =>
                    Theme(data: theme(context), child: child!),
                home: Center(
                  child: SizedBox.fromSize(
                    size: size,
                    child: FirstAccessSceneView(motion: motion),
                  ),
                ),
              ),
            );
            expect(tester.takeException(), isNull, reason: '$size');
          }
        }
      }
    });
  });
}
