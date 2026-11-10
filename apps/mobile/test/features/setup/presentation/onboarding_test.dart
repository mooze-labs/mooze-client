import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/setup/presentation/providers/onboarding_provider.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/onboarding/widgets/onboarding_scene.dart';
import 'package:mooze_mobile/features/setup/presentation/services/onboarding_service.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:mooze_mobile/themes/motion.dart';

import '../../../shared/widgets/motion/motion_test_helpers.dart';
import 'setup_test_app.dart';

/// Records the end of the onboarding, without storage.
class _FakeOnboardingService extends OnboardingService {
  bool completed = false;

  @override
  Future<void> setOnboardingCompleted() async => completed = true;
}

void main() {
  late OpenedRoutes opened;
  late _FakeOnboardingService service;

  setUp(() {
    opened = OpenedRoutes();
    service = _FakeOnboardingService();
  });

  /// The onboarding as the first screen of the setup, in Portuguese.
  Future<AppLocalizations> open(
    WidgetTester tester, {
    double textScale = 1,
  }) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      setupTestApp(
        router: GoRouter(
          initialLocation: '/setup/onboarding',
          routes: [
            GoRoute(
              path: '/setup/onboarding',
              builder: (_, _) => const OnboardingScreen(),
            ),
            opened.stub('/setup/first-access'),
          ],
        ),
        overrides: [onboardingServiceProvider.overrideWithValue(service)],
        textScale: textScale,
      ),
    );
    await tester.pump();
    return lookupAppLocalizations(const Locale('pt'));
  }

  /// The onboarding alone, in [language], ending with [onDone].
  Future<AppLocalizations> openIn(
    WidgetTester tester,
    String language, {
    VoidCallback? onDone,
  }) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [onboardingServiceProvider.overrideWithValue(service)],
        child: MaterialApp(
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              Theme(data: AppTheme.lightTheme(context), child: child!),
          home: OnboardingScreen(onDone: onDone),
        ),
      ),
    );
    await tester.pump();
    return lookupAppLocalizations(Locale(language));
  }

  /// Taps "Next" and lets the page slide in.
  Future<void> next(WidgetTester tester, AppLocalizations t) async {
    await tester.tap(find.text(t.common_next));
    await tester.pumpAndSettle();
  }

  /// The art of the page in view.
  SceneMotion motionOf(WidgetTester tester, Finder art) =>
      tester.widget<OnboardingSceneView>(art).motion;

  for (final language in ['pt', 'en', 'es']) {
    testWidgets('$language: the four pages speak the language of the app', (
      tester,
    ) async {
      final t = await openIn(tester, language);
      final pages = [
        (t.onboarding_1_eyebrow, t.onboarding_1_title, t.onboarding_1_body),
        (t.onboarding_2_eyebrow, t.onboarding_2_title, t.onboarding_2_body),
        (t.onboarding_3_eyebrow, t.onboarding_3_title, t.onboarding_3_body),
        (t.onboarding_4_eyebrow, t.onboarding_4_title, t.onboarding_4_body),
      ];

      for (final (i, (eyebrow, title, body)) in pages.indexed) {
        if (i > 0) await next(tester, t);
        expect(find.text(eyebrow), findsOneWidget);
        expect(find.text(title, findRichText: true), findsOneWidget);
        expect(find.text(body), findsOneWidget);
      }
      expect(find.text(t.onboarding_get_started), findsOneWidget);
      expect(find.text(t.common_next), findsNothing);
    });

    testWidgets('$language: each title shows its highlight in the brand '
        'color', (tester) async {
      final t = await openIn(tester, language);
      final highlights = [
        (t.onboarding_1_title, t.onboarding_1_highlight),
        (t.onboarding_2_title, t.onboarding_2_highlight),
        (t.onboarding_3_title, t.onboarding_3_highlight),
        (t.onboarding_4_title, t.onboarding_4_highlight),
      ];

      for (final (i, (title, highlight)) in highlights.indexed) {
        if (i > 0) await next(tester, t);
        final text = tester.widget<RichText>(
          find.text(title, findRichText: true),
        );
        final brand = Theme.of(
          tester.element(find.byType(OnboardingScreen)),
        ).colorScheme.primary;
        final spans = <TextSpan>[];
        text.text.visitChildren((span) {
          if (span is TextSpan && span.text != null) spans.add(span);
          return true;
        });
        expect(
          spans.where((span) => span.style?.color == brand).single.text,
          highlight,
          reason: title,
        );
      }
    });
  }

  testWidgets('the last button marks the onboarding as done and opens the '
      'first access screen', (tester) async {
    final t = await open(tester);
    for (var i = 0; i < 3; i++) {
      await next(tester, t);
    }

    await tester.tap(find.text(t.onboarding_get_started));
    await settle(tester);

    expect(service.completed, isTrue);
    expect(opened.last, '/setup/first-access');
  });

  testWidgets('skip ends the onboarding from the first page, and hides on '
      'the last one', (tester) async {
    final t = await open(tester);

    await tester.tap(find.text(t.onboarding_skip));
    await settle(tester);

    expect(service.completed, isTrue);
    expect(opened.last, '/setup/first-access');
  });

  testWidgets('skip hides on the last page', (tester) async {
    final t = await openIn(tester, 'pt');
    for (var i = 0; i < 3; i++) {
      await next(tester, t);
    }

    final skip = tester.widget<AnimatedOpacity>(
      find.ancestor(
        of: find.text(t.onboarding_skip),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(skip.opacity, 0);
    await tester.tap(find.text(t.onboarding_skip), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(service.completed, isFalse);
  });

  testWidgets('a preview ends with its own callback: the onboarding stays '
      'to do', (tester) async {
    var done = 0;
    final t = await openIn(tester, 'pt', onDone: () => done++);

    await tester.tap(find.text(t.onboarding_skip));
    await tester.pumpAndSettle();

    expect(done, 1);
    expect(service.completed, isFalse);
  });

  testWidgets('the art enters, drifts, and rests within 5 s: nothing loops', (
    tester,
  ) async {
    await openIn(tester, 'pt');
    final art = find.byType(OnboardingSceneView);

    await tester.pump(Motion.durationOnboardingScene ~/ 2);
    expect(motionOf(tester, art).entrance, inExclusiveRange(0, 1));

    // 5 s in all: the longest an animation may play on its own.
    await tester.pump(
      const Duration(seconds: 5) - Motion.durationOnboardingScene ~/ 2,
    );
    expect(motionOf(tester, art).time, 1);
    // An animation ends one frame after its last value.
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('a page shown again keeps its art at rest', (tester) async {
    final t = await openIn(tester, 'pt');
    await tester.pump(Motion.durationAmbient * 2);
    await next(tester, t);

    await tester.drag(find.byType(PageView), const Offset(400, 0));
    await tester.pump();
    final art = find.byType(OnboardingSceneView);
    expect(motionOf(tester, art.first).time, 1);
  });

  testWidgets('the art of a page plays as soon as a third of it shows, and '
      'turns with the finger', (tester) async {
    await openIn(tester, 'pt');
    await tester.pump(Motion.durationAmbient * 2);

    final gesture = await tester.startGesture(const Offset(300, 300));
    await gesture.moveBy(const Offset(-80, 0));
    await tester.pump();
    // 40% of the next page shows: it has not become the current page yet.
    await gesture.moveBy(const Offset(-76, 0));
    // The clock starts on the next frame, then runs.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final arts = tester
        .widgetList<OnboardingSceneView>(find.byType(OnboardingSceneView))
        .toList();
    expect(arts, hasLength(2));
    expect(arts.first.motion.offset, inExclusiveRange(-0.5, -1 / 3));
    expect(arts.last.motion.offset, inExclusiveRange(0.5, 2 / 3));
    expect(arts.last.motion.entrance, greaterThan(0));
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('with reduced motion, the art is still and Next jumps', (
    tester,
  ) async {
    reduceMotion(tester);
    final t = await openIn(tester, 'pt');
    await tester.pump();

    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(motionOf(tester, find.byType(OnboardingSceneView)).time, 1);

    await tester.tap(find.text(t.common_next));
    await tester.pump();
    expect(find.text(t.onboarding_2_title, findRichText: true), findsOneWidget);
    final art = tester.widget<OnboardingSceneView>(
      find.byType(OnboardingSceneView),
    );
    expect(art.motion.time, 1);
    expect(art.motion.offset, 0);
  });

  testWidgets('the art has the same room on every page', (tester) async {
    final t = await openIn(tester, 'pt');
    final sizes = <Size>[];
    for (var i = 0; i < 4; i++) {
      if (i > 0) await next(tester, t);
      sizes.add(tester.getSize(find.byType(OnboardingSceneView)));
    }

    expect(sizes.toSet(), hasLength(1));
  });

  testWidgets('fits a phone at 200% text', (tester) async {
    final t = await open(tester, textScale: 2);
    await tester.pump(Motion.durationAmbient * 2);
    for (var i = 0; i < 3; i++) {
      await next(tester, t);
    }

    expect(tester.takeException(), isNull);
    expect(find.text(t.onboarding_get_started), findsOneWidget);
  });
}
