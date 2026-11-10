import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_copy_field.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/transaction_confirmed_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/receive_celebration.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/stage/glyph_colors.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:mooze_mobile/themes/motion.dart';

import '../../../../shared/widgets/motion/motion_test_helpers.dart';

void main() {
  final t = lookupAppLocalizations(const Locale('pt'));
  const step = Duration(milliseconds: 10);

  /// Haptics played, with the time since the screen opened.
  late List<(String, Duration)> haptics;
  late Duration clock;

  setUp(() {
    haptics = [];
    clock = Duration.zero;
  });

  /// The confirmation of [amount] of [asset] as the first screen, so its
  /// entrance starts at once. [txid] tells the transactions apart: the
  /// entrance plays once per transaction.
  Future<void> pump(
    WidgetTester tester, {
    required String txid,
    Asset asset = Asset.lbtc,
    int amount = 1234,
    bool lightTheme = false,
  }) async {
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
        home: TransactionConfirmedScreen(
          asset: asset,
          amount: BigInt.from(amount),
          transactionId: txid,
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

  /// How much shows of [finder], through the fades above it.
  double shown(WidgetTester tester, Finder finder) => tester
      .widgetList<FadeTransition>(
        find.ancestor(of: finder, matching: find.byType(FadeTransition)),
      )
      .fold(1.0, (value, fade) => value * fade.opacity.value);

  final amount = find.textContaining('1.234', findRichText: true);

  testWidgets('three haptics follow the entrance: heavy as it starts, '
      'medium with the shockwave, light as the coin lands', (tester) async {
    await pump(tester, txid: 'haptics');
    await advance(tester, Motion.durationReceive);

    expect(
      [for (final (type, _) in haptics) type],
      [
        'HapticFeedbackType.heavyImpact',
        'HapticFeedbackType.mediumImpact',
        'HapticFeedbackType.lightImpact',
      ],
    );
    // The medium impact comes while the shockwave grows, before the coin
    // shows; the light one when the coin lands, about 0.7 s in.
    expect(haptics[0].$2, lessThanOrEqualTo(const Duration(milliseconds: 20)));
    expect(haptics[1].$2.inMilliseconds, inInclusiveRange(100, 300));
    expect(haptics[2].$2.inMilliseconds, inInclusiveRange(550, 800));
  });

  testWidgets('a scene that starts midway plays no haptics', (tester) async {
    final controller = AnimationController(
      vsync: const TestVSync(),
      duration: Motion.durationReceive,
      value: 0.5,
    );
    addTearDown(controller.dispose);
    await pump(tester, txid: 'midway-host');
    await advance(tester, Motion.durationReceive);
    haptics.clear();

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            Theme(data: AppTheme.darkTheme(context), child: child!),
        home: ReceiveCelebration(asset: Asset.btc, animation: controller),
      ),
    );
    controller.forward();
    await advance(tester, Motion.durationReceive);

    expect(haptics, isEmpty);
  });

  testWidgets('the scene rests after about 1.6 s: nothing loops', (
    tester,
  ) async {
    await pump(tester, txid: 'rests');

    await advance(tester, const Duration(milliseconds: 1500));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await advance(tester, const Duration(milliseconds: 150));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('the amount appears once the scene rests, after the coin', (
    tester,
  ) async {
    await pump(tester, txid: 'reveal');

    await advance(tester, Motion.durationReceive * 0.6);
    expect(shown(tester, amount), 0);
    expect(shown(tester, find.text(t.tx_confirmed_title)), 0);

    await advance(tester, Motion.durationReceive * 0.45);
    expect(shown(tester, amount), 1);
    expect(find.text(t.tx_received_asset('L-BTC')), findsOneWidget);
    expect(find.text(t.tx_received), findsOneWidget);
    expect(
      tester.widget<PixCopyField>(find.byType(PixCopyField)).value,
      'reveal',
    );
  });

  testWidgets('the entrance plays once per transaction', (tester) async {
    await pump(tester, txid: 'once');
    await advance(tester, Motion.durationReceive);
    expect(haptics, hasLength(3));

    await tester.pumpWidget(const SizedBox());
    haptics.clear();
    await pump(tester, txid: 'once');
    await tester.pump();

    expect(haptics, isEmpty);
    expect(shown(tester, amount), 1);
  });

  testWidgets('with reduced motion, the scene rests at once with one light '
      'haptic', (tester) async {
    reduceMotion(tester);
    await pump(tester, txid: 'reduced');
    await tester.pump();

    expect(shown(tester, amount), 1);
    expect(
      [for (final (type, _) in haptics) type],
      ['HapticFeedbackType.lightImpact'],
    );
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  for (final asset in Asset.values) {
    testWidgets('the coin of ${asset.ticker} carries its icon in the brand '
        'pink', (tester) async {
      await pump(tester, txid: 'coin-${asset.ticker}', asset: asset);
      await advance(tester, Motion.durationReceive);

      final context = tester.element(find.byType(ReceiveCelebration));
      final pink = Theme.of(context).colorScheme.primary;
      final glyph =
          tester
                  .widget<SvgPicture>(
                    find
                        .descendant(
                          of: find.byType(ReceiveCelebration),
                          matching: find.byType(SvgPicture),
                        )
                        .last,
                  )
                  .bytesLoader
              as SvgAssetLoader;
      expect(glyph.assetName, asset.iconPath);
      expect(glyph.colorMapper, CoinGlyphColors.of(asset, pink));
    });
  }

  for (final lightTheme in [false, true]) {
    testWidgets('the stage follows the ${lightTheme ? 'light' : 'dark'} '
        'theme', (tester) async {
      await pump(tester, txid: 'theme-$lightTheme', lightTheme: lightTheme);
      await advance(tester, Motion.durationReceive);

      final background = tester
          .widget<Scaffold>(find.byType(Scaffold))
          .backgroundColor!;
      final title = tester
          .widget<Text>(find.text(t.tx_confirmed_title))
          .style!
          .color!;
      final context = tester.element(find.byType(ReceiveCelebration));
      expect(
        Theme.of(context).brightness,
        lightTheme ? Brightness.light : Brightness.dark,
      );
      if (lightTheme) {
        // A pearl page, dark text, and dark icons on the status bar.
        expect(background.computeLuminance(), greaterThan(0.85));
        expect(title.computeLuminance(), lessThan(0.05));
        expect(
          tester
              .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
                find.byType(AnnotatedRegion<SystemUiOverlayStyle>).last,
              )
              .value,
          SystemUiOverlayStyle.dark,
        );
      } else {
        expect(background.computeLuminance(), lessThan(0.01));
        expect(title.computeLuminance(), greaterThan(0.8));
      }
    });
  }

  testWidgets('a token shows its own unit', (tester) async {
    await pump(tester, txid: 'token', asset: Asset.usdt, amount: 150000000);
    await advance(tester, Motion.durationReceive);

    expect(find.textContaining('1,50', findRichText: true), findsOneWidget);
    expect(find.textContaining('USDT', findRichText: true), findsWidgets);
  });

  testWidgets('opened from a screen, it fades in, plays, and its button '
      'closes it', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) =>
            Theme(data: AppTheme.lightTheme(context), child: child!),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => TransactionConfirmedScreen.show(
              context,
              asset: Asset.btc,
              amount: BigInt.from(5000),
              transactionId: 'shown',
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(TransactionConfirmedScreen), findsOneWidget);

    await tester.tap(find.text(t.tx_back_to_dashboard));
    await tester.pumpAndSettle();
    expect(find.byType(TransactionConfirmedScreen), findsNothing);
  });

  group('CoinGlyphColors', () {
    const pink = Color(0xFFEA1E63);

    Color map(Asset asset, int source) => CoinGlyphColors.of(
      asset,
      pink,
    ).substitute(null, 'path', 'fill', Color(source));

    test('the disc of an icon clears, so the coin shows behind the '
        'symbol', () {
      expect(map(Asset.btc, 0xFFF7931A), Colors.transparent);
      expect(map(Asset.btc, 0xFFFFFFFF), pink);
      expect(map(Asset.usdt, 0xFF26A17B), Colors.transparent);
      expect(map(Asset.usdt, 0xFFFFFFFF), pink);
    });

    test('the L-BTC drop and the DePix bar dim, so their symbols keep two '
        'tones', () {
      expect(map(Asset.lbtc, 0xFF46BEAE).a, closeTo(0.45, 0.01));
      expect(map(Asset.lbtc, 0xFFFEFFFE), pink);
      expect(map(Asset.depix, 0xFF366378).a, closeTo(0.45, 0.01));
      expect(map(Asset.depix, 0xFF62D1CA), pink);
    });

    test('equal mappers are equal, so the icons share their cache', () {
      expect(
        CoinGlyphColors.of(Asset.btc, pink),
        CoinGlyphColors.of(Asset.btc, pink),
      );
      expect(
        CoinGlyphColors.of(Asset.btc, pink),
        isNot(CoinGlyphColors.of(Asset.usdt, pink)),
      );
    });
  });
}
