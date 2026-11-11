import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/buttons/slide_to_confirm_button.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

import '../motion/motion_test_helpers.dart';

void main() {
  final t = lookupAppLocalizations(const Locale('pt'));
  const step = Duration(milliseconds: 16);
  const label = 'Confirmar Swap';

  /// The share of the track past which a release confirms.
  const confirmAt = 0.8;

  /// The screen is 390 pt wide, and the button keeps 24 pt from each side,
  /// as in a bottom sheet. Its track is narrower than the screen.
  const screenWidth = 390.0;
  const margin = 24.0;

  late ValueNotifier<bool> loading;
  late int slides;
  late List<String> haptics;

  setUp(() {
    loading = ValueNotifier(false);
    slides = 0;
    haptics = [];
  });

  /// The button in a screen, with the callback that a confirm screen gives
  /// it: it counts the slides and, if [startsLoading], starts loading.
  Future<void> pump(
    WidgetTester tester, {
    bool startsLoading = true,
    bool isEnabled = true,
    bool lightTheme = false,
  }) async {
    tester.view.physicalSize = const Size(screenWidth, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    addTearDown(loading.dispose);
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
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: margin),
              child: ValueListenableBuilder<bool>(
                valueListenable: loading,
                builder: (context, isLoading, _) => SlideToConfirmButton(
                  text: label,
                  isLoading: isLoading,
                  isEnabled: isEnabled,
                  onSlideComplete: () {
                    slides++;
                    if (startsLoading) loading.value = true;
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  final button = find.byType(SlideToConfirmButton);

  /// The thumb that the user drags, found as the screen tests find it.
  final thumb = find.descendant(
    of: button,
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is GestureDetector && widget.onHorizontalDragEnd != null,
    ),
  );

  /// The distance of the thumb from the start of the track.
  double offsetOf(WidgetTester tester) =>
      tester.getRect(thumb).left - tester.getRect(button).left;

  /// The distance that the thumb travels from the start to the end.
  double travelOf(WidgetTester tester) =>
      tester.getRect(button).width - tester.getRect(thumb).width;

  /// Pumps [time] in frames.
  Future<void> advance(WidgetTester tester, Duration time) async {
    for (var elapsed = Duration.zero; elapsed < time; elapsed += step) {
      await tester.pump(step);
    }
  }

  /// The opacity over the label, with every fade above it.
  double labelOpacity(WidgetTester tester) => tester
      .widgetList<FadeTransition>(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(FadeTransition),
        ),
      )
      .fold(1.0, (value, fade) => value * fade.opacity.value);

  Color? colorOf(Decoration decoration) => switch (decoration) {
    BoxDecoration(:final color) => color,
    ShapeDecoration(:final color) => color,
    _ => null,
  };

  testWidgets('the thumb stays inside the track as it slides to the end and '
      'loads, in a track narrower than the screen', (tester) async {
    await pump(tester);
    final track = tester.getRect(button);
    expect(track.width, screenWidth - margin * 2);

    final gesture = await tester.startGesture(tester.getCenter(thumb));
    for (var i = 0; i < 40; i++) {
      await gesture.moveBy(const Offset(12, 0));
      await tester.pump(step);
      expect(tester.getRect(thumb).right, lessThanOrEqualTo(track.right));
    }
    await gesture.up();
    await advance(tester, const Duration(seconds: 1));

    expect(slides, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.getRect(thumb).right, moreOrLessEquals(track.right));
    expect(tester.getRect(thumb).left, greaterThan(track.left));
  });

  testWidgets('the thumb follows the finger from the point where it was '
      'grabbed', (tester) async {
    await pump(tester);
    // Off its centre, so that a thumb that jumps under the finger shows.
    final gesture = await tester.startGesture(
      tester.getRect(thumb).centerRight - const Offset(8, 0),
    );
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(70, 0));
    await tester.pump();
    expect(offsetOf(tester), moreOrLessEquals(100, epsilon: 0.5));

    await gesture.moveBy(const Offset(-40, 0));
    await tester.pump();
    expect(offsetOf(tester), moreOrLessEquals(60, epsilon: 0.5));

    await gesture.up();
    await advance(tester, const Duration(seconds: 1));
  });

  testWidgets('a trail fills the track behind the thumb, up to the whole '
      'track at the end', (tester) async {
    await pump(tester);
    final onPrimary = Theme.of(tester.element(button)).colorScheme.onPrimary;
    final trail = find.descendant(
      of: button,
      matching: find.byWidgetPredicate((widget) {
        if (widget is! DecoratedBox) return false;
        final color = colorOf(widget.decoration);
        return color != null &&
            color.a < 1 &&
            color.withValues(alpha: 1) == onPrimary;
      }),
    );
    final track = tester.getRect(button);
    expect(tester.getRect(trail).left, track.left);
    expect(tester.getRect(trail).right, tester.getRect(thumb).right);

    final gesture = await tester.startGesture(tester.getCenter(thumb));
    await gesture.moveBy(const Offset(100, 0));
    await tester.pump();
    expect(tester.getRect(trail).left, track.left);
    expect(tester.getRect(trail).right, tester.getRect(thumb).right);

    await gesture.moveBy(const Offset(400, 0));
    await gesture.up();
    await advance(tester, const Duration(seconds: 1));
    expect(tester.getRect(trail), track);
  });

  testWidgets('a release before the threshold springs the thumb back to the '
      'start and confirms nothing', (tester) async {
    await pump(tester);
    final travel = travelOf(tester);
    final gesture = await tester.startGesture(tester.getCenter(thumb));
    await gesture.moveBy(Offset(travel * 0.6, 0));
    await tester.pump();
    await gesture.up();

    // It moves back over frames: it does not jump.
    await tester.pump(step);
    await tester.pump(step);
    expect(offsetOf(tester), inExclusiveRange(travel * 0.3, travel * 0.6));

    await advance(tester, const Duration(seconds: 1));
    expect(offsetOf(tester), moreOrLessEquals(0, epsilon: 0.5));
    expect(slides, 0);
    expect(haptics, isEmpty);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('crossing the threshold ticks and turns the arrow into a check; '
      'the release confirms at once with a medium haptic, and the thumb goes '
      'to the end', (tester) async {
    await pump(tester);
    final travel = travelOf(tester);
    final gesture = await tester.startGesture(tester.getCenter(thumb));
    await gesture.moveBy(Offset(travel * (confirmAt - 0.05), 0));
    await tester.pump();
    expect(haptics, isEmpty);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);

    await gesture.moveBy(Offset(travel * 0.1, 0));
    await tester.pump();
    expect(haptics, ['HapticFeedbackType.selectionClick']);
    await advance(tester, const Duration(milliseconds: 300));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
    expect(slides, 0);

    await gesture.up();
    expect(slides, 1);
    expect(haptics, [
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.mediumImpact',
    ]);

    await advance(tester, const Duration(seconds: 1));
    expect(offsetOf(tester), moreOrLessEquals(travel, epsilon: 0.5));
    expect(slides, 1);
  });

  testWidgets('when the slide starts no loading, as when the screen cannot '
      'confirm yet, the thumb returns to the start and slides again', (
    tester,
  ) async {
    await pump(tester, startsLoading: false);

    await tester.drag(thumb, const Offset(800, 0));
    expect(slides, 1);
    await advance(tester, const Duration(seconds: 1));
    expect(offsetOf(tester), moreOrLessEquals(0, epsilon: 0.5));
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);

    await tester.drag(thumb, const Offset(800, 0));
    expect(slides, 2);
    await advance(tester, const Duration(seconds: 1));
  });

  testWidgets('the thumb waits at the end with a spinner while the screen '
      'loads, and returns with the arrow when the loading ends', (
    tester,
  ) async {
    await pump(tester);
    await tester.drag(thumb, const Offset(800, 0));
    await advance(tester, const Duration(seconds: 1));
    final travel = travelOf(tester);
    expect(offsetOf(tester), moreOrLessEquals(travel, epsilon: 0.5));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(t.common_processing), findsOneWidget);

    // The action failed, so the screen stays.
    loading.value = false;
    await advance(tester, const Duration(seconds: 1));
    expect(offsetOf(tester), moreOrLessEquals(0, epsilon: 0.5));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    expect(find.text(label), findsOneWidget);
  });

  testWidgets('a loading that starts during a drag, as a quote refresh, takes '
      'the thumb back, and that drag no longer moves it', (tester) async {
    await pump(tester);
    final gesture = await tester.startGesture(tester.getCenter(thumb));
    await gesture.moveBy(const Offset(120, 0));
    await tester.pump();
    expect(offsetOf(tester), moreOrLessEquals(120, epsilon: 0.5));

    loading.value = true;
    await advance(tester, const Duration(seconds: 1));
    expect(offsetOf(tester), moreOrLessEquals(0, epsilon: 0.5));

    await gesture.moveBy(const Offset(400, 0));
    await tester.pump();
    expect(offsetOf(tester), moreOrLessEquals(0, epsilon: 0.5));
    await gesture.up();
    expect(slides, 0);

    // Once the loading ends, the thumb slides again.
    loading.value = false;
    await advance(tester, const Duration(milliseconds: 300));
    await tester.drag(thumb, const Offset(800, 0));
    expect(slides, 1);
    await advance(tester, const Duration(seconds: 1));
  });

  testWidgets('while the screen loads before any slide, the thumb stays at the '
      'start with a spinner, dimmed, and a drag does not move it', (
    tester,
  ) async {
    loading.value = true;
    await pump(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(t.common_processing), findsOneWidget);
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.descendant(of: button, matching: find.byType(AnimatedOpacity)),
          )
          .opacity,
      0.4,
    );

    await tester.drag(thumb, const Offset(800, 0));
    await advance(tester, const Duration(milliseconds: 500));
    expect(slides, 0);
    expect(offsetOf(tester), moreOrLessEquals(0, epsilon: 0.5));
  });

  testWidgets('a disabled button shows its thumb dimmed, and a drag neither '
      'moves it nor confirms', (tester) async {
    await pump(tester, isEnabled: false);
    expect(thumb, findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.descendant(of: button, matching: find.byType(AnimatedOpacity)),
          )
          .opacity,
      0.4,
    );

    await tester.drag(thumb, const Offset(800, 0));
    await advance(tester, const Duration(milliseconds: 500));
    expect(slides, 0);
    expect(offsetOf(tester), moreOrLessEquals(0, epsilon: 0.5));
  });

  testWidgets('a tap nudges the thumb to show that it slides, and confirms '
      'nothing', (tester) async {
    await pump(tester);
    await tester.tap(button);

    var peak = 0.0;
    for (var i = 0; i < 20; i++) {
      await tester.pump(step);
      peak = math.max(peak, offsetOf(tester));
    }
    expect(peak, greaterThan(16));

    await advance(tester, const Duration(seconds: 1));
    expect(offsetOf(tester), moreOrLessEquals(0, epsilon: 0.5));
    expect(slides, 0);
    expect(haptics, isEmpty);
  });

  testWidgets('the label fades as the thumb slides over it, and comes back', (
    tester,
  ) async {
    await pump(tester);
    expect(labelOpacity(tester), 1);

    final gesture = await tester.startGesture(tester.getCenter(thumb));
    await gesture.moveBy(Offset(travelOf(tester) * 0.3, 0));
    await tester.pump();
    expect(labelOpacity(tester), inExclusiveRange(0, 1));

    await gesture.up();
    await advance(tester, const Duration(seconds: 1));
    expect(labelOpacity(tester), 1);
  });

  testWidgets('a screen reader finds a button with the label, and its tap '
      'confirms', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);

    expect(
      tester.getSemantics(button),
      isSemantics(
        label: label,
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    tester.semantics.tap(find.semantics.byLabel(label));
    await tester.pump();
    expect(slides, 1);
    expect(haptics, ['HapticFeedbackType.mediumImpact']);

    await advance(tester, const Duration(seconds: 1));
    semantics.dispose();
  });

  testWidgets('with a screen reader on, a plain tap confirms', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(accessibleNavigation: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pump(tester);

    await tester.tap(button);
    expect(slides, 1);
    await advance(tester, const Duration(seconds: 1));
  });

  testWidgets('with reduced motion the thumb jumps to the end on a release '
      'past the threshold and back when the loading ends, and a tap does not '
      'nudge it', (tester) async {
    reduceMotion(tester);
    await pump(tester);
    final travel = travelOf(tester);

    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.tap(button);
    // The nudge does not even start.
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pump();
    await tester.pump(step);
    expect(offsetOf(tester), 0);

    final gesture = await tester.startGesture(tester.getCenter(thumb));
    await gesture.moveBy(Offset(travel * 0.9, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(slides, 1);
    expect(offsetOf(tester), moreOrLessEquals(travel, epsilon: 0.5));

    loading.value = false;
    await tester.pump();
    expect(offsetOf(tester), moreOrLessEquals(0, epsilon: 0.5));
    // The switchers drop the spinner and the old label in one more frame.
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('at rest the button schedules no frames', (tester) async {
    await pump(tester);
    await advance(tester, const Duration(seconds: 2));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  for (final lightTheme in [false, true]) {
    testWidgets('it takes its colors from the '
        '${lightTheme ? 'light' : 'dark'} theme', (tester) async {
      await pump(tester, lightTheme: lightTheme);
      final scheme = Theme.of(tester.element(button)).colorScheme;

      Finder filled(Color color) => find.descendant(
        of: button,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is DecoratedBox && colorOf(widget.decoration) == color,
        ),
      );
      // The track, and the thumb on it.
      expect(filled(scheme.primary), findsOneWidget);
      expect(filled(scheme.onPrimary), findsOneWidget);
      expect(
        tester.widget<Text>(find.text(label)).style?.color,
        scheme.onPrimary,
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.arrow_forward_rounded)).color,
        scheme.primary,
      );
    });
  }
}
