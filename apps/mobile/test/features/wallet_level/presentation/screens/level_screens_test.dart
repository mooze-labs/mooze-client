import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/screens/level_downgrade_screen.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/screens/level_upgrade_screen.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/utils/wallet_level_ui_helpers.dart';
import 'package:mooze_mobile/features/wallet_level/presentation/widgets/level_celebration.dart';
import 'package:mooze_mobile/shared/widgets/stage/glyph_colors.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:mooze_mobile/themes/motion.dart';

import '../../../../shared/widgets/motion/motion_test_helpers.dart';

void main() {
  const step = Duration(milliseconds: 10);

  /// Haptics played, with the time since the screen opened.
  late List<(String, Duration)> haptics;
  late Duration clock;

  setUp(() {
    haptics = [];
    clock = Duration.zero;
  });

  /// [screen] in [language] as the first screen, so its entrance starts at
  /// once.
  Future<AppLocalizations> pump(
    WidgetTester tester,
    Widget screen, {
    String language = 'pt',
    bool lightTheme = false,
  }) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
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
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => Theme(
          data: lightTheme
              ? AppTheme.lightTheme(context)
              : AppTheme.darkTheme(context),
          child: child!,
        ),
        home: screen,
      ),
    );
    return lookupAppLocalizations(Locale(language));
  }

  /// Pumps [time] in small steps, advancing [clock].
  Future<void> advance(WidgetTester tester, Duration time) async {
    final end = clock + time;
    while (clock < end) {
      await tester.pump(step);
      clock += step;
    }
  }

  /// The face of the medal that shows: 0 the old level, 1 the new one.
  int shownFace(WidgetTester tester) => tester
      .widget<IndexedStack>(
        find.descendant(
          of: find.byType(LevelCelebration),
          matching: find.byType(IndexedStack),
        ),
      )
      .index!;

  /// The emblems on the faces of the medal, old level first. Each face
  /// draws its emblem twice: its shadow, then the emblem.
  List<String> faceEmblems(WidgetTester tester) => {
    for (final emblem in tester.widgetList<SvgPicture>(
      find.descendant(
        of: find.byType(IndexedStack),
        // The face that does not show yet is built, so its emblem is
        // ready when the medal turns.
        matching: find.byType(SvgPicture, skipOffstage: false),
        skipOffstage: false,
      ),
    ))
      (emblem.bytesLoader as SvgAssetLoader).assetName,
  }.toList();

  const up = LevelUpgradeScreen(oldLevel: 1, newLevel: 2);
  const down = LevelDowngradeScreen(oldLevel: 2, newLevel: 1);

  for (final language in ['pt', 'en', 'es']) {
    testWidgets('$language: the upgrade speaks the language of the app', (
      tester,
    ) async {
      final t = await pump(tester, up, language: language);
      await tester.pumpAndSettle();

      expect(find.textContaining(t.level_up_badge), findsOneWidget);
      expect(find.text(t.level_up_title), findsOneWidget);
      expect(find.text(t.level_up_message), findsOneWidget);
      expect(find.text(t.common_continue), findsOneWidget);
      // The new level under the medal and in the pill, the old one in the
      // pill.
      expect(find.text(t.level_name_gold), findsNWidgets(2));
      expect(find.text(t.level_name_silver), findsOneWidget);
    });

    testWidgets('$language: the downgrade speaks the language of the app', (
      tester,
    ) async {
      final t = await pump(tester, down, language: language);
      await tester.pumpAndSettle();

      expect(find.textContaining(t.level_down_badge), findsOneWidget);
      expect(find.text(t.level_down_title), findsOneWidget);
      expect(find.text(t.level_down_message), findsOneWidget);
      expect(find.text(t.level_down_tip), findsOneWidget);
      expect(find.text(t.common_understood), findsOneWidget);
      expect(find.text(t.level_name_silver), findsNWidgets(2));
      expect(find.text(t.level_name_gold), findsOneWidget);
    });
  }

  testWidgets('in English, no Portuguese text is left', (tester) async {
    await pump(tester, up, language: 'en');
    await tester.pumpAndSettle();
    for (final portuguese in ['nível', 'Ouro', 'Prata', 'Continuar']) {
      expect(find.textContaining(portuguese), findsNothing, reason: portuguese);
    }

    await pump(tester, down, language: 'en');
    await tester.pumpAndSettle();
    for (final portuguese in ['nível', 'Dica', 'Entendi', 'Ouro']) {
      expect(find.textContaining(portuguese), findsNothing, reason: portuguese);
    }
  });

  testWidgets('up, three haptics follow the medal: light as it spins up, '
      'heavy as the new level shows, light as it lands', (tester) async {
    await pump(tester, up);
    await advance(tester, Motion.durationLevelChange);

    expect(
      [for (final (type, _) in haptics) type],
      [
        'HapticFeedbackType.lightImpact',
        'HapticFeedbackType.heavyImpact',
        'HapticFeedbackType.lightImpact',
      ],
    );
    expect(haptics[0].$2.inMilliseconds, inInclusiveRange(200, 320));
    expect(haptics[1].$2.inMilliseconds, inInclusiveRange(850, 960));
    expect(haptics[2].$2.inMilliseconds, inInclusiveRange(1300, 1430));
  });

  testWidgets('down, one light haptic as the new level shows', (tester) async {
    await pump(tester, down);
    await advance(tester, Motion.durationLevelChange);

    expect(
      [for (final (type, _) in haptics) type],
      ['HapticFeedbackType.lightImpact'],
    );
    expect(haptics.single.$2.inMilliseconds, inInclusiveRange(740, 850));
  });

  for (final (name, screen, reveal) in [
    ('up', up as Widget, LevelCelebration.upRevealAt),
    ('down', down as Widget, LevelCelebration.downRevealAt),
  ]) {
    testWidgets('$name, the medal turns from the old level to the new one '
        'with the reveal haptic', (tester) async {
      await pump(tester, screen);
      expect(faceEmblems(tester), [
        WalletLevelUiHelpers.getLevelEmblem(name == 'up' ? 1 : 2),
        WalletLevelUiHelpers.getLevelEmblem(name == 'up' ? 2 : 1),
      ]);

      final revealAt = Motion.durationLevelChange * reveal;
      await advance(tester, revealAt - const Duration(milliseconds: 40));
      expect(shownFace(tester), 0);
      final before = haptics.length;

      await advance(tester, const Duration(milliseconds: 60));
      expect(shownFace(tester), 1);
      expect(haptics, hasLength(before + 1));
    });

    testWidgets('$name, the scene rests after 1.8 s: nothing loops', (
      tester,
    ) async {
      await pump(tester, screen);

      await advance(tester, const Duration(milliseconds: 1700));
      expect(tester.binding.hasScheduledFrame, isTrue);
      await advance(tester, const Duration(milliseconds: 150));
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(shownFace(tester), 1);
    });

    testWidgets('$name, with reduced motion the scene rests at once with '
        'one light haptic', (tester) async {
      reduceMotion(tester);
      final t = await pump(tester, screen);
      await tester.pump();

      expect(shownFace(tester), 1);
      expect(
        [for (final (type, _) in haptics) type],
        ['HapticFeedbackType.lightImpact'],
      );
      expect(tester.binding.hasScheduledFrame, isFalse);
      final button = name == 'up' ? t.common_continue : t.common_understood;
      expect(
        tester
            .widget<FadeTransition>(
              find
                  .ancestor(
                    of: find.text(button),
                    matching: find.byType(FadeTransition),
                  )
                  .first,
            )
            .opacity
            .value,
        1,
      );
    });

    for (final lightTheme in [false, true]) {
      testWidgets('$name, the stage follows the '
          '${lightTheme ? 'light' : 'dark'} theme', (tester) async {
        await pump(tester, screen, lightTheme: lightTheme);
        await tester.pumpAndSettle();

        final background = tester
            .widget<Scaffold>(find.byType(Scaffold))
            .backgroundColor!;
        final context = tester.element(find.byType(LevelCelebration));
        final brightness = lightTheme ? Brightness.light : Brightness.dark;
        expect(Theme.of(context).brightness, brightness);
        expect(
          background.computeLuminance(),
          lightTheme ? greaterThan(0.85) : lessThan(0.01),
        );
        // The emblem of the new level takes the tint of the theme.
        final newLevel = name == 'up' ? 2 : 1;
        final emblem = tester.widget<SvgPicture>(
          find
              .descendant(
                of: find.byType(LevelCelebration),
                matching: find.byType(SvgPicture),
              )
              .last,
        );
        expect(
          (emblem.bytesLoader as SvgAssetLoader).colorMapper,
          TwoToneGlyphColors(
            WalletLevelUiHelpers.getLevelTint(newLevel, brightness),
          ),
        );
      });
    }
  }

  testWidgets('a scene that jumps to rest plays no haptics', (tester) async {
    final controller = AnimationController(
      vsync: const TestVSync(),
      duration: Motion.durationLevelChange,
    );
    addTearDown(controller.dispose);
    await pump(
      tester,
      LevelCelebration(oldLevel: 1, newLevel: 2, animation: controller),
    );

    controller.value = 1;
    await tester.pump();

    expect(haptics, isEmpty);
  });

  testWidgets('the headline shows once the medal rests', (tester) async {
    final t = await pump(tester, up);

    double shown(Finder finder) => tester
        .widgetList<FadeTransition>(
          find.ancestor(of: finder, matching: find.byType(FadeTransition)),
        )
        .fold(1.0, (value, fade) => value * fade.opacity.value);

    await advance(tester, Motion.durationLevelChange * 0.6);
    expect(shown(find.text(t.level_up_title)), 0);

    await advance(tester, Motion.durationLevelChange * 0.45);
    expect(shown(find.text(t.level_up_title)), 1);
    expect(shown(find.text(t.common_continue)), 1);
  });

  testWidgets('screen readers hear the badge without its ornaments', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final t = await pump(tester, up);
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel(t.level_up_badge), findsOneWidget);
    handle.dispose();
  });

  group('emblems', () {
    test('every level has its own emblem, drawn in the two colors that '
        'TwoToneGlyphColors maps', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final paths = {
        for (var level = 0; level < 4; level++)
          WalletLevelUiHelpers.getLevelEmblem(level),
      };
      expect(paths, hasLength(4));
      for (final path in paths) {
        final svg = await rootBundle.loadString(path);
        final colors = RegExp(
          '#[0-9A-Fa-f]{6}',
        ).allMatches(svg).map((m) => m[0]!.toUpperCase()).toSet();
        expect(colors, {'#FFFFFF', '#8E8E93'}, reason: path);
      }
    });

    test('the tints of the light theme are deeper than those of the dark '
        'theme, so the medals show on a light page', () {
      for (var level = 0; level < 4; level++) {
        final dark = WalletLevelUiHelpers.getLevelTint(level, Brightness.dark);
        final light = WalletLevelUiHelpers.getLevelTint(
          level,
          Brightness.light,
        );
        expect(
          light.computeLuminance(),
          lessThan(dark.computeLuminance() * 0.75),
          reason: 'level $level',
        );
      }
    });

    test('light faces take the tint and faces in shade a dimmed tint', () {
      const gold = Color(0xFFFFD54A);
      Color map(int source) => const TwoToneGlyphColors(
        gold,
      ).substitute(null, 'path', 'fill', Color(source));

      expect(map(0xFFFFFFFF), gold);
      expect(map(0xFF8E8E93).a, closeTo(0.5, 0.01));
      expect(map(0xFF8E8E93).toARGB32() & 0xFFFFFF, gold.toARGB32() & 0xFFFFFF);
    });

    test('equal mappers are equal, so the emblems share their cache', () {
      expect(
        const TwoToneGlyphColors(Color(0xFFFFD54A)),
        const TwoToneGlyphColors(Color(0xFFFFD54A)),
      );
      expect(
        const TwoToneGlyphColors(Color(0xFFFFD54A)),
        isNot(const TwoToneGlyphColors(Color(0xFF7B9CFF))),
      );
    });
  });
}
