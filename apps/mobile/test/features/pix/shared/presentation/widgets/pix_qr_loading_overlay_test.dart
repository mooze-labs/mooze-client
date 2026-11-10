import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_qr_loading_overlay.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_qr_scene.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_palette.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:mooze_mobile/themes/motion.dart';

import '../../../../../shared/widgets/motion/motion_test_helpers.dart';

void main() {
  final t = lookupAppLocalizations(const Locale('pt'));
  const step = Duration(milliseconds: 10);

  /// The stage opening, then the code assembling.
  final entrance = Motion.durationSlow + PixQrLoadingOverlay.assembleDuration;

  /// Haptics played, with the time since the scene showed.
  late List<(String, Duration)> haptics;
  late Duration clock;
  late PixQrLoadingOverlay loading;
  late BuildContext home;
  late int taps;
  late int opened;

  setUp(() {
    haptics = [];
    clock = Duration.zero;
    taps = 0;
    opened = 0;
  });

  void recordHaptics(WidgetTester tester) {
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        haptics.add((call.arguments as String, clock));
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
  }

  /// A screen with a button, then the scene over it.
  Future<void> show(WidgetTester tester, {bool lightTheme = false}) async {
    recordHaptics(tester);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => Theme(
          data: lightTheme
              ? AppTheme.lightTheme(context)
              : AppTheme.darkTheme(context),
          child: child!,
        ),
        home: Builder(
          builder: (context) {
            home = context;
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => taps++,
                  child: const Text('below'),
                ),
              ),
            );
          },
        ),
      ),
    );
    loading = PixQrLoadingOverlay.show(home, text: t.pix_generating_qr);
    await tester.pump();
  }

  /// Opens the next screen, as a charge screen opens its QR code.
  void openNext() {
    opened++;
    Navigator.of(home).push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('next')),
      ),
    );
  }

  /// Pumps [time] in small steps, advancing [clock].
  Future<void> advance(WidgetTester tester, Duration time) async {
    final end = clock + time;
    while (clock < end) {
      await tester.pump(step);
      clock += step;
    }
  }

  PixQrMotion motion(WidgetTester tester) =>
      tester.widget<PixQrScene>(find.byType(PixQrScene)).motion;

  List<String> types() => [for (final (type, _) in haptics) type];

  final scene = find.byType(PixQrScene);

  testWidgets('the stage covers the screen, then the code assembles, with '
      'one light haptic as it starts', (tester) async {
    await show(tester);

    await advance(tester, Motion.durationSlow * 0.75);
    expect(motion(tester).assemble, 0);
    expect(haptics, isEmpty);

    await advance(tester, Motion.durationSlow * 0.5);
    expect(motion(tester).assemble, greaterThan(0));
    expect(types(), ['HapticFeedbackType.lightImpact']);
    expect(haptics.single.$2.inMilliseconds, inInclusiveRange(380, 460));

    await advance(tester, PixQrLoadingOverlay.assembleDuration);
    expect(motion(tester).assemble, 1);
    expect(find.text(t.pix_generating_qr), findsOneWidget);
  });

  testWidgets('it blocks taps on the screen below, from its first frame', (
    tester,
  ) async {
    await show(tester);
    await tester.tap(find.text('below'), warnIfMissed: false);
    expect(taps, 0);

    // The stage still grows from the bottom, short of the button.
    await advance(tester, Motion.durationSlow * 0.25);
    await tester.tap(find.text('below'), warnIfMissed: false);
    expect(taps, 0);

    await advance(tester, entrance);
    await tester.tap(find.text('below'), warnIfMissed: false);
    expect(taps, 0);
  });

  testWidgets('while the request runs, a beam scans the code and the scene '
      'keeps moving', (tester) async {
    await show(tester);
    await advance(tester, entrance + const Duration(seconds: 2));

    final before = motion(tester).cycle;
    await advance(tester, const Duration(milliseconds: 500));
    expect(motion(tester).cycle, isNot(before));
    expect(motion(tester).waiting, 1);
    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('succeed locks the code in with a heavy haptic, opens the '
      'next screen halfway through, then fades away', (tester) async {
    await show(tester);
    await advance(tester, entrance + const Duration(seconds: 1));
    haptics.clear();
    final at = clock;
    var closed = false;
    loading.succeed(openNext).then((_) => closed = true);

    await advance(tester, Motion.durationCelebrate * 0.4);
    expect(types(), ['HapticFeedbackType.heavyImpact']);
    expect(haptics.single.$2 - at, lessThanOrEqualTo(step * 2));
    expect(motion(tester).finale, greaterThan(0));
    expect(motion(tester).waiting, lessThan(1));
    expect(opened, 0);

    await advance(tester, Motion.durationCelebrate * 0.2);
    expect(opened, 1);
    // The next screen opens under the scene, which still covers it.
    expect(scene, findsOneWidget);
    expect(closed, isFalse);

    // Once the code has locked in, the scene fades away over the next
    // screen.
    await advance(
      tester,
      Motion.durationCelebrate * 0.4 + Motion.durationSlow * 0.6,
    );
    expect(scene, findsOneWidget);
    final fade = tester
        .widgetList<Opacity>(
          find.ancestor(of: scene, matching: find.byType(Opacity)),
        )
        .fold(1.0, (value, opacity) => value * opacity.opacity);
    expect(fade, inExclusiveRange(0, 1));

    await advance(tester, Motion.durationSlow * 0.4 + step * 8);
    expect(scene, findsNothing);
    expect(find.text('next'), findsOneWidget);
    expect(closed, isTrue);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('succeed waits for the code to assemble', (tester) async {
    await show(tester);
    loading.succeed(openNext);

    await advance(tester, entrance - const Duration(milliseconds: 100));
    expect(opened, 0);
    expect(types(), ['HapticFeedbackType.lightImpact']);

    await advance(
      tester,
      const Duration(milliseconds: 100) + Motion.durationCelebrate,
    );
    expect(opened, 1);
    expect(types(), [
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.heavyImpact',
    ]);
  });

  testWidgets('fail fades the scene away at once and opens nothing', (
    tester,
  ) async {
    await show(tester);
    await advance(tester, entrance + const Duration(seconds: 1));
    expect(scene, findsOneWidget);
    haptics.clear();
    var closed = false;
    loading.fail().then((_) => closed = true);

    await advance(tester, Motion.durationExit + step * 3);
    expect(scene, findsNothing);
    expect(closed, isTrue);
    expect(opened, 0);
    expect(haptics, isEmpty);
  });

  testWidgets('a failure during the entrance does not wait for the code', (
    tester,
  ) async {
    await show(tester);
    await advance(tester, Motion.durationSlow * 0.5);
    expect(scene, findsOneWidget);

    loading.fail();
    await advance(tester, Motion.durationExit + step * 3);
    expect(scene, findsNothing);
  });

  testWidgets('cancel removes the scene at once while it waits', (
    tester,
  ) async {
    await show(tester);
    await advance(tester, entrance);
    expect(scene, findsOneWidget);

    loading.cancel();
    await tester.pump();
    expect(scene, findsNothing);
    await tester.tap(find.text('below'));
    expect(taps, 1);
  });

  testWidgets('cancel does not cut an ending: the next screen still opens', (
    tester,
  ) async {
    await show(tester);
    await advance(tester, entrance);

    loading.succeed(openNext);
    loading.cancel();
    await advance(
      tester,
      Motion.durationCelebrate + Motion.durationSlow + step * 8,
    );
    expect(opened, 1);
    expect(scene, findsNothing);
  });

  testWidgets('after 15 s the caption adds that it takes longer', (
    tester,
  ) async {
    await show(tester);

    await tester.pump(
      PixQrLoadingOverlay.slowAfter - const Duration(seconds: 1),
    );
    expect(find.text(t.common_taking_longer), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text(t.common_taking_longer), findsOneWidget);
  });

  testWidgets('the caption is a live region, and the screen below is hidden '
      'from screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    await show(tester);
    await advance(tester, entrance);

    expect(
      tester.getSemantics(find.text(t.pix_generating_qr)),
      isSemantics(label: t.pix_generating_qr, isLiveRegion: true),
    );
    expect(find.semantics.byLabel('below'), findsNothing);
    semantics.dispose();
  });

  testWidgets('with reduced motion the code shows at once and does not '
      'move, and succeed opens the next screen at once with one light '
      'haptic', (tester) async {
    reduceMotion(tester);
    await show(tester);
    await tester.pump();

    expect(motion(tester).assemble, 1);
    expect(motion(tester).waiting, 0);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(haptics, isEmpty);

    loading.succeed(openNext);
    await tester.pump();
    expect(opened, 1);
    expect(types(), ['HapticFeedbackType.lightImpact']);
    await tester.pumpAndSettle();
    expect(scene, findsNothing);
    expect(find.text('next'), findsOneWidget);
  });

  for (final lightTheme in [false, true]) {
    testWidgets('the stage follows the ${lightTheme ? 'light' : 'dark'} '
        'theme', (tester) async {
      await show(tester, lightTheme: lightTheme);
      await advance(tester, entrance);

      final palette = StagePalette.of(tester.element(scene));
      expect(palette.isDark, !lightTheme);
      final stage = tester.widget<ColoredBox>(
        find.ancestor(of: scene, matching: find.byType(ColoredBox)).first,
      );
      expect(stage.color, palette.page);
      expect(
        tester
            .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
              find.byType(AnnotatedRegion<SystemUiOverlayStyle>).last,
            )
            .value,
        lightTheme ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      );
    });
  }
}
