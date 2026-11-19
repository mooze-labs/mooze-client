import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/widgets/level_emblem.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/user/providers/levels_provider.dart';
import 'package:mooze_mobile/shared/widgets/buttons/secondary_button.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/user_level_card.dart';
import 'package:mooze_mobile/shared/widgets/user_level_display.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:mooze_mobile/themes/motion.dart';

import 'motion/motion_test_helpers.dart';

void main() {
  final t = lookupAppLocalizations(const Locale('pt'));

  /// [child] in Portuguese, in a column of [width] on a phone screen.
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Brightness brightness = Brightness.dark,
    double width = 350,
    double textScale = 1,
    List<Override> overrides = const [],
  }) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: Theme(
              data: brightness == Brightness.dark
                  ? AppTheme.darkTheme(context)
                  : AppTheme.lightTheme(context),
              child: child!,
            ),
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Center(
                child: SizedBox(width: width, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The fill of each groove, in order: the lines between the markers,
  /// then the bar to the next level.
  List<double> fills(WidgetTester tester) => tester
      .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))
      .map((box) => box.widthFactor!)
      .toList();

  UserLevelsData data({int level = 1, double progress = 0.4}) => UserLevelsData(
    spendingLevel: level,
    levelProgress: progress,
    allowedSpending: 500,
    dailySpending: 0,
    currentLevelMinLimit: 20,
    currentLevelMaxLimit: 500,
    absoluteMinLimit: 20,
    absoluteMaxLimit: 3000,
    remainingLimit: 5000,
  );

  group('UserLevelCard', () {
    testWidgets('a glass panel with the title, the number of the level, '
        'every level by name, and the progress to the next one', (
      tester,
    ) async {
      await pump(
        tester,
        const UserLevelCard(currentLevel: 1, currentProgress: 0.4),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GlassPanel), findsOneWidget);
      expect(find.text(t.level_my_levels), findsOneWidget);
      expect(find.text(t.level_label(2)), findsOneWidget);
      for (final name in ['Bronze', 'Prata', 'Ouro', 'Diamante']) {
        expect(find.text(name), findsOneWidget);
      }
      expect(
        find.text(
          '${t.level_current}${t.level_name_silver}',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(find.text(t.level_progress(40)), findsOneWidget);
      expect(find.text(t.level_next(t.level_name_gold)), findsOneWidget);
      // One emblem per marker, and one in the pill.
      expect(find.byType(LevelEmblem), findsNWidgets(5));
    });

    testWidgets('the line behind the user is full, the line of the current '
        'level and the bar fill to the progress, and the line ahead is '
        'empty', (tester) async {
      await pump(
        tester,
        const UserLevelCard(currentLevel: 1, currentProgress: 0.4),
      );
      await tester.pumpAndSettle();

      expect(fills(tester), [1, 0.4, 0, 0.4]);
    });

    testWidgets('the progress fills in when the card shows, and the '
        'percentage shows its final value at once', (tester) async {
      await pump(
        tester,
        const UserLevelCard(currentLevel: 1, currentProgress: 0.4),
      );

      expect(fills(tester)[3], 0);
      expect(find.text(t.level_progress(40)), findsOneWidget);

      await tester.pump(Motion.durationChartDraw ~/ 2);
      expect(fills(tester)[3], inExclusiveRange(0, 0.4));

      await tester.pumpAndSettle();
      expect(fills(tester)[3], 0.4);
    });

    testWidgets('a new progress moves the bar from the old value', (
      tester,
    ) async {
      await pump(
        tester,
        const UserLevelCard(currentLevel: 1, currentProgress: 0.4),
      );
      await tester.pumpAndSettle();

      await pump(
        tester,
        const UserLevelCard(currentLevel: 1, currentProgress: 0.8),
      );
      await tester.pump(Motion.durationChartDraw ~/ 2);
      expect(fills(tester)[3], inExclusiveRange(0.4, 0.8));

      await tester.pumpAndSettle();
      expect(fills(tester)[3], 0.8);
      expect(find.text(t.level_progress(80)), findsOneWidget);
    });

    testWidgets('under reduced motion the progress shows at once', (
      tester,
    ) async {
      reduceMotion(tester);
      await pump(
        tester,
        const UserLevelCard(currentLevel: 2, currentProgress: 0.6),
      );
      await tester.pump();

      expect(fills(tester), [1, 1, 0.6, 0.6]);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('at the last level, no bar and no next level', (tester) async {
      await pump(tester, const UserLevelCard(currentLevel: 3));
      await tester.pumpAndSettle();

      expect(
        find.text(
          '${t.level_current}${t.level_name_diamond}',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(find.textContaining(t.level_next('')), findsNothing);
      // Only the three lines of the track: all behind the user.
      expect(fills(tester), [1, 1, 1]);
    });

    testWidgets('plain has no panel and no title', (tester) async {
      await pump(
        tester,
        const UserLevelCard.plain(currentLevel: 0, currentProgress: 0.2),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LiquidGlass), findsNothing);
      expect(find.text(t.level_my_levels), findsNothing);
      expect(find.text(t.level_progress(20)), findsOneWidget);
    });

    testWidgets('a tap reaches onTap in both variants', (tester) async {
      var taps = 0;
      await pump(
        tester,
        Column(
          children: [
            UserLevelCard(currentLevel: 0, onTap: () => taps++),
            UserLevelCard.plain(currentLevel: 0, onTap: () => taps++),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.level_my_levels));
      await tester.tap(find.text('Prata').last);
      expect(taps, 2);
    });

    for (final brightness in Brightness.values) {
      testWidgets('fits a 320 pt screen at 200% text in the '
          '${brightness.name} theme', (tester) async {
        await pump(
          tester,
          const Column(
            children: [
              UserLevelCard(currentLevel: 3, currentProgress: 1),
              UserLevelCard(currentLevel: 1, currentProgress: 0.55),
              UserLevelCardSkeleton(),
              UserLevelCardSkeleton.plain(),
            ],
          ),
          brightness: brightness,
          width: 280,
          textScale: 2,
        );
        // The skeletons shimmer in a loop, so the test waits for the bars
        // to fill instead of for every animation to end.
        await tester.pump(Motion.durationChartDraw);

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('UserLevelDisplay', () {
    testWidgets('shows the plain card once the level loads', (tester) async {
      await pump(
        tester,
        const UserLevelDisplay(),
        overrides: [
          levelsProvider.overrideWith(
            (ref) async => data(level: 2, progress: 0.25),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.byType(UserLevelCard), findsOneWidget);
      expect(find.byType(LiquidGlass), findsNothing);
      expect(find.text(t.level_progress(25)), findsOneWidget);
      expect(find.text(t.level_next(t.level_name_diamond)), findsOneWidget);
    });

    testWidgets('shows a skeleton in the shape of the card while the level '
        'loads', (tester) async {
      final pending = Completer<UserLevelsData>();
      await pump(
        tester,
        const UserLevelDisplay(),
        overrides: [levelsProvider.overrideWith((ref) => pending.future)],
      );
      await tester.pump();

      expect(find.byType(UserLevelCardSkeleton), findsOneWidget);
      expect(find.byType(UserLevelCard), findsNothing);

      pending.complete(data());
      await tester.pumpAndSettle();
      expect(find.byType(UserLevelCardSkeleton), findsNothing);
      expect(find.byType(UserLevelCard), findsOneWidget);
    });

    testWidgets('shows the error with a retry button if the level fails', (
      tester,
    ) async {
      await pump(
        tester,
        const UserLevelDisplay(),
        overrides: [
          levelsProvider.overrideWith((ref) async => throw Exception('down')),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text(t.level_load_error), findsOneWidget);
      expect(find.byType(SecondaryButton), findsOneWidget);
      expect(find.byType(UserLevelCard), findsNothing);
    });
  });
}
