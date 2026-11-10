import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/swap/presentation/screens/swap_success_screen.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart' as core;
import 'package:mooze_mobile/shared/widgets/stage/stage_turn.dart';
import 'package:mooze_mobile/themes/app_text_styles.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:mooze_mobile/themes/motion.dart';

import '../../../shared/widgets/motion/motion_test_helpers.dart';

void main() {
  final t = lookupAppLocalizations(const Locale('pt'));
  const step = Duration(milliseconds: 10);

  /// Haptics played, with the time since the screen opened.
  late List<(String, Duration)> haptics;
  late Duration clock;

  // The amounts sit in one row; the app font keeps them in it.
  setUpAll(() async {
    final loader = FontLoader(AppTextStyles.fontFamily);
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(
        rootBundle.load('assets/fonts/geist-font/Geist/ttf/Geist-$weight.ttf'),
      );
    }
    await loader.load();
  });

  setUp(() {
    haptics = [];
    clock = Duration.zero;
  });

  /// The end of a swap of 500 DePix to 0.001135 L-BTC as the first screen,
  /// so its entrance starts at once.
  Future<void> pump(WidgetTester tester, {bool lightTheme = false}) async {
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
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => Theme(
          data: lightTheme
              ? AppTheme.lightTheme(context)
              : AppTheme.darkTheme(context),
          child: child!,
        ),
        home: const SwapSuccessScreen(
          fromAsset: core.Asset.depix,
          toAsset: core.Asset.lbtc,
          amountSent: 500,
          amountReceived: 0.001135,
          txid: 'f3a9c1d2e4b5a69788776655443322110',
        ),
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

  /// The face of the coin that shows: 0 the sent asset, 1 the received.
  int shownFace(WidgetTester tester) => tester
      .widget<IndexedStack>(
        find.descendant(
          of: find.byType(StageTurn),
          matching: find.byType(IndexedStack),
        ),
      )
      .index!;

  /// How much shows of [finder], through the fades above it.
  double shown(WidgetTester tester, Finder finder) => tester
      .widgetList<FadeTransition>(
        find.ancestor(of: finder, matching: find.byType(FadeTransition)),
      )
      .fold(1.0, (value, fade) => value * fade.opacity.value);

  testWidgets('the coin of the sent asset spins up and turns into the coin '
      'of the received one', (tester) async {
    await pump(tester);
    final icons = {
      for (final icon in tester.widgetList<SvgPicture>(
        find.descendant(
          of: find.byType(IndexedStack),
          matching: find.byType(SvgPicture, skipOffstage: false),
          skipOffstage: false,
        ),
      ))
        (icon.bytesLoader as SvgAssetLoader).assetName,
    };
    // The face of the sent asset first; each face draws its icon twice,
    // its shadow and the icon.
    expect(icons.toList(), [
      core.Asset.depix.iconPath,
      core.Asset.lbtc.iconPath,
    ]);

    final reveal = Motion.durationSwap * StageTurn.upRevealAt;
    await advance(tester, reveal - const Duration(milliseconds: 40));
    expect(shownFace(tester), 0);
    await advance(tester, const Duration(milliseconds: 60));
    expect(shownFace(tester), 1);
  });

  testWidgets('three haptics follow the coin: light as it spins up, heavy as '
      'it turns, light as it lands', (tester) async {
    await pump(tester);
    await advance(tester, Motion.durationSwap);

    expect(
      [for (final (type, _) in haptics) type],
      [
        'HapticFeedbackType.lightImpact',
        'HapticFeedbackType.heavyImpact',
        'HapticFeedbackType.lightImpact',
      ],
    );
    expect(haptics[1].$2.inMilliseconds, inInclusiveRange(850, 960));
  });

  testWidgets('the amounts show in the units of their assets: sats for '
      'L-BTC, DEPIX for DePix', (tester) async {
    await pump(tester);
    await advance(tester, Motion.durationSwap);

    expect(find.textContaining('−500,00', findRichText: true), findsOneWidget);
    expect(find.textContaining('DEPIX', findRichText: true), findsOneWidget);
    expect(find.textContaining('+113.500', findRichText: true), findsOneWidget);
    expect(find.textContaining('sats', findRichText: true), findsOneWidget);
    expect(find.text(t.swap_you_send), findsOneWidget);
    expect(find.text(t.swap_you_receive), findsOneWidget);
  });

  testWidgets('the title shows once the coin lands, then the summary', (
    tester,
  ) async {
    await pump(tester);

    await advance(tester, Motion.durationSwap * 0.6);
    expect(shown(tester, find.text(t.swap_success_title)), 0);
    expect(shown(tester, find.text(t.swap_you_receive)), 0);

    await advance(tester, Motion.durationSwap * 0.45);
    expect(shown(tester, find.text(t.swap_success_title)), 1);
    expect(shown(tester, find.text(t.swap_you_receive)), 1);
  });

  testWidgets('the scene rests after 1.8 s: nothing loops', (tester) async {
    await pump(tester);

    await advance(
      tester,
      Motion.durationSwap - const Duration(milliseconds: 100),
    );
    expect(tester.binding.hasScheduledFrame, isTrue);
    await advance(tester, const Duration(milliseconds: 150));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('with reduced motion, the scene rests at once with one light '
      'haptic', (tester) async {
    reduceMotion(tester);
    await pump(tester);
    await tester.pump();

    expect(shownFace(tester), 1);
    expect(shown(tester, find.text(t.swap_success_title)), 1);
    expect(
      [for (final (type, _) in haptics) type],
      ['HapticFeedbackType.lightImpact'],
    );
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  for (final lightTheme in [false, true]) {
    testWidgets('the stage follows the ${lightTheme ? 'light' : 'dark'} '
        'theme', (tester) async {
      await pump(tester, lightTheme: lightTheme);
      await advance(tester, Motion.durationSwap);

      final background = tester
          .widget<Scaffold>(find.byType(Scaffold))
          .backgroundColor!;
      expect(
        background.computeLuminance(),
        lightTheme ? greaterThan(0.85) : lessThan(0.01),
      );
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
