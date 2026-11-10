import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/domain/events/sync_outcome.dart';
import 'package:mooze_mobile/domain/failures/failure.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_copy_field.dart';
import 'package:mooze_mobile/features/sync/domain/sync_orchestrator.dart';
import 'package:mooze_mobile/features/sync/domain/sync_strategy.dart';
import 'package:mooze_mobile/features/wallet/domain/usecases/refresh_wallet.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/address_controller_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/address_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/amount_controller_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/amount_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/selected_asset_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/send_funds/transaction_sent_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/send_celebration.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/stage/glyph_colors.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:mooze_mobile/themes/motion.dart';

import '../../../../../shared/widgets/motion/motion_test_helpers.dart';

/// A sample destination, not a real address.
const _address = 'lq1qqsample0destination0for0the0sent0screen0tests';

/// Records the refreshes, without a wallet.
class _FakeSync extends Fake implements SyncOrchestrator {
  final strategies = <SyncStrategy>[];

  @override
  Future<Either<SyncFailure, SyncOutcome>> refresh({
    SyncStrategy strategy = SyncStrategy.light,
  }) {
    strategies.add(strategy);
    // The screen does not wait for the outcome.
    return Completer<Either<SyncFailure, SyncOutcome>>().future;
  }
}

void main() {
  final t = lookupAppLocalizations(const Locale('pt'));
  const step = Duration(milliseconds: 10);

  late _FakeSync sync;

  /// Haptics played, with the time since the screen opened.
  late List<(String, Duration)> haptics;
  late Duration clock;

  setUp(() {
    sync = _FakeSync();
    haptics = [];
    clock = Duration.zero;
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

  Override refreshOverride() =>
      refreshWalletProvider.overrideWith((ref) => RefreshWalletUseCase(sync));

  Widget theme(BuildContext context, Widget? child, {bool light = false}) =>
      Theme(
        data: light
            ? AppTheme.lightTheme(context)
            : AppTheme.darkTheme(context),
        child: child!,
      );

  /// The end of a send of [amount] of [asset] as the first screen, so its
  /// scene starts at once.
  Future<void> pump(
    WidgetTester tester, {
    Asset asset = Asset.lbtc,
    int amount = 25400,
    String? txid = 'sent-txid',
    bool lightTheme = false,
    VoidCallback? onDone,
  }) async {
    recordHaptics(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [refreshOverride()],
        child: MaterialApp(
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => theme(context, child, light: lightTheme),
          home: TransactionSentScreen(
            asset: asset,
            amount: BigInt.from(amount),
            destinationAddress: _address,
            transactionId: txid,
            onDone: onDone,
          ),
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

  List<String> copied(WidgetTester tester) => [
    for (final field in tester.widgetList<PixCopyField>(
      find.byType(PixCopyField),
    ))
      field.value,
  ];

  final amount = find.textContaining('25.400', findRichText: true);

  testWidgets('three haptics follow the flight: light as the plane comes '
      'out from behind the coin, heavy as it breaks away, light as it gets '
      'far', (tester) async {
    await pump(tester);
    await advance(tester, Motion.durationSend);

    expect(
      [for (final (type, _) in haptics) type],
      [
        'HapticFeedbackType.lightImpact',
        'HapticFeedbackType.heavyImpact',
        'HapticFeedbackType.lightImpact',
      ],
    );
    // The plane breaks away halfway through the 1.8 s, and gets far about
    // 0.45 s later.
    expect(haptics[0].$2.inMilliseconds, inInclusiveRange(150, 450));
    expect(haptics[1].$2.inMilliseconds, inInclusiveRange(880, 940));
    expect(haptics[2].$2.inMilliseconds, inInclusiveRange(1340, 1400));
  });

  testWidgets('a scene that starts midway plays no haptics', (tester) async {
    recordHaptics(tester);
    final controller = AnimationController(
      vsync: const TestVSync(),
      duration: Motion.durationSend,
      value: 0.5,
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: theme,
        home: SendCelebration(asset: Asset.btc, animation: controller),
      ),
    );
    controller.forward();
    await advance(tester, Motion.durationSend);

    expect(haptics, isEmpty);
  });

  testWidgets('the scene rests after about 1.8 s: nothing loops', (
    tester,
  ) async {
    await pump(tester);

    await advance(tester, const Duration(milliseconds: 1700));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await advance(tester, const Duration(milliseconds: 150));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('the title and the amount appear once the plane is away', (
    tester,
  ) async {
    await pump(tester);

    await advance(tester, Motion.durationSend * 0.6);
    expect(shown(tester, amount), 0);
    expect(shown(tester, find.text(t.tx_sent_title)), 0);

    await advance(tester, Motion.durationSend * 0.45);
    expect(shown(tester, amount), 1);
    expect(find.text(t.tx_sent_subtitle('L-BTC')), findsOneWidget);
    expect(find.text(t.tx_sent_status_label), findsOneWidget);
  });

  testWidgets('the destination and the transaction ID show in copy fields, '
      'after the amount', (tester) async {
    await pump(tester, txid: 'abc123');

    await advance(tester, Motion.durationSend * 0.75);
    expect(shown(tester, find.byType(PixCopyField).first), lessThan(0.5));

    await advance(tester, Motion.durationSend * 0.3);
    expect(copied(tester), [_address, 'abc123']);
    expect(shown(tester, find.byType(PixCopyField).first), 1);
    expect(shown(tester, find.text(t.tx_sent_track_history)), 1);
  });

  for (final txid in [null, '']) {
    testWidgets('without a transaction ID ("$txid"), only the destination '
        'shows', (tester) async {
      await pump(tester, txid: txid);
      await advance(tester, Motion.durationSend);

      expect(copied(tester), [_address]);
    });
  }

  testWidgets('sats show with their separators, and a token in its own '
      'unit', (tester) async {
    await pump(tester, asset: Asset.btc);
    await advance(tester, Motion.durationSend);
    expect(amount, findsOneWidget);
    expect(find.textContaining('sats', findRichText: true), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await pump(tester, asset: Asset.usdt, amount: 150000000);
    await advance(tester, Motion.durationSend);
    expect(find.textContaining('1,50', findRichText: true), findsOneWidget);
    expect(find.textContaining('USDT', findRichText: true), findsWidgets);
  });

  testWidgets('with reduced motion, the scene rests at once with one light '
      'haptic', (tester) async {
    reduceMotion(tester);
    await pump(tester);
    await tester.pump();

    expect(shown(tester, amount), 1);
    expect(
      [for (final (type, _) in haptics) type],
      ['HapticFeedbackType.lightImpact'],
    );
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('a change of the theme does not play the scene again', (
    tester,
  ) async {
    reduceMotion(tester);
    await pump(tester);
    await tester.pump();

    await pump(tester, lightTheme: true);
    await tester.pump();

    expect(
      [for (final (type, _) in haptics) type],
      ['HapticFeedbackType.lightImpact'],
    );
  });

  for (final asset in Asset.values) {
    testWidgets('the coin of ${asset.ticker} carries its icon in the brand '
        'pink', (tester) async {
      await pump(tester, asset: asset);
      await advance(tester, Motion.durationSend);

      final context = tester.element(find.byType(SendCelebration));
      final pink = Theme.of(context).colorScheme.primary;
      final glyph =
          tester
                  .widget<SvgPicture>(
                    find
                        .descendant(
                          of: find.byType(SendCelebration),
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
      await pump(tester, lightTheme: lightTheme);
      await advance(tester, Motion.durationSend);

      final background = tester
          .widget<Scaffold>(find.byType(Scaffold))
          .backgroundColor!;
      final title = tester
          .widget<Text>(find.text(t.tx_sent_title))
          .style!
          .color!;
      final context = tester.element(find.byType(SendCelebration));
      expect(
        Theme.of(context).brightness,
        lightTheme ? Brightness.light : Brightness.dark,
      );
      final statusBar = tester
          .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
            find.byType(AnnotatedRegion<SystemUiOverlayStyle>).last,
          )
          .value;
      if (lightTheme) {
        // A pearl page, dark text, and dark icons on the status bar.
        expect(background.computeLuminance(), greaterThan(0.85));
        expect(title.computeLuminance(), lessThan(0.05));
        expect(statusBar, SystemUiOverlayStyle.dark);
      } else {
        expect(background.computeLuminance(), lessThan(0.01));
        expect(title.computeLuminance(), greaterThan(0.8));
        expect(statusBar, SystemUiOverlayStyle.light);
      }
    });
  }

  testWidgets('the balances refresh once, a second after it opens', (
    tester,
  ) async {
    await pump(tester);

    await advance(tester, const Duration(milliseconds: 900));
    expect(sync.strategies, isEmpty);
    await advance(tester, const Duration(milliseconds: 200));
    expect(sync.strategies, [SyncStrategy.light]);
    await advance(tester, Motion.durationSend);
    expect(sync.strategies, hasLength(1));
  });

  testWidgets('its button clears the send form and goes home', (tester) async {
    recordHaptics(tester);
    final container = ProviderContainer(overrides: [refreshOverride()]);
    addTearDown(container.dispose);
    container.read(addressStateProvider.notifier).state = _address;
    container.read(addressControllerProvider).text = _address;
    container.read(amountStateProvider.notifier).state = 25400;
    container.read(amountControllerProvider).text = '25400';
    container.read(formattedAmountProvider.notifier).state = '25.400';
    container.read(selectedAssetProvider.notifier).state = Asset.btc;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: theme,
          routerConfig: GoRouter(
            initialLocation: '/sent',
            routes: [
              GoRoute(
                path: '/sent',
                builder: (_, _) => TransactionSentScreen(
                  asset: Asset.btc,
                  amount: BigInt.from(25400),
                  destinationAddress: _address,
                ),
              ),
              GoRoute(path: '/home', builder: (_, _) => const Text('home')),
            ],
          ),
        ),
      ),
    );
    await advance(tester, Motion.durationSend);

    await tester.tap(find.text(t.refund_success_back_dashboard));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    expect(container.read(addressStateProvider), isEmpty);
    expect(container.read(addressControllerProvider).text, isEmpty);
    expect(container.read(amountStateProvider), 0);
    expect(container.read(amountControllerProvider).text, isEmpty);
    expect(container.read(formattedAmountProvider), '0');
    expect(container.read(selectedAssetProvider), Asset.lbtc);
  });

  testWidgets('with onDone, its button and the back gesture run it instead, '
      'and the send form stays', (tester) async {
    var done = 0;
    await pump(tester, onDone: () => done++);
    await advance(tester, Motion.durationSend);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(TransactionSentScreen)),
    );
    container.read(addressStateProvider.notifier).state = _address;

    await tester.tap(find.text(t.refund_success_back_dashboard));
    await tester.pump();
    expect(done, 1);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(done, 2);
    expect(find.byType(TransactionSentScreen), findsOneWidget);
    expect(container.read(addressStateProvider), _address);
  });

  testWidgets('opened from a screen, it fades in, then plays, and closes '
      'through onDone', (tester) async {
    recordHaptics(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [refreshOverride()],
        child: MaterialApp(
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => theme(context, child, light: true),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => TransactionSentScreen.show(
                context,
                asset: Asset.btc,
                amount: BigInt.from(5000),
                destinationAddress: _address,
                transactionId: 'shown',
                onDone: () => Navigator.of(context).pop(),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await advance(
      tester,
      Motion.durationBase + Motion.durationSend + const Duration(seconds: 1),
    );
    expect(find.byType(TransactionSentScreen), findsOneWidget);
    expect(haptics, hasLength(3));
    // The scene starts once the screen is in place: the plane comes out
    // from behind the coin after the fade.
    expect(
      haptics.first.$2,
      greaterThan(Motion.durationBase + const Duration(milliseconds: 300)),
    );

    await tester.tap(find.text(t.refund_success_back_dashboard));
    await tester.pumpAndSettle();
    expect(find.byType(TransactionSentScreen), findsNothing);
  });

  group('the flight of the plane', () {
    final plane = SendCelebration.planeAt;

    test('it starts hidden behind the coin', () {
      final start = plane(0);
      expect(start.behind, isTrue);
      expect(start.position.distance, lessThan(0.8));
    });

    test('it passes under the coin, in front of it, and nearer than when it '
        'was behind it', () {
      final flight = [for (var i = 0; i <= 100; i++) plane(i / 100)];
      final lowest = flight.reduce(
        (a, b) => a.position.dy >= b.position.dy ? a : b,
      );
      expect(lowest.behind, isFalse);
      expect(lowest.position.dy, greaterThan(0.9));
      expect(lowest.position.dx.abs(), lessThan(0.5));
      expect(lowest.scale, greaterThan(plane(0).scale));
    });

    test('it breaks away at the boost: it moves fastest just after it', () {
      double travel(double from, double to) =>
          (plane(to).position - plane(from).position).distance;
      const boost = SendCelebration.boostAt;
      expect(
        travel(boost, boost + 0.02),
        greaterThan(2 * travel(boost - 0.02, boost)),
      );
    });

    test('it rests far up to the right, pointing up and to the right', () {
      final rest = plane(1);
      expect(rest.behind, isFalse);
      expect(rest.position.dx, greaterThan(1.5));
      expect(rest.position.dy, lessThan(-1));
      expect(rest.heading, inExclusiveRange(-math.pi / 2, 0));
      expect(rest.scale, lessThan(0.85));
      expect(plane(SendCelebration.arriveAt), rest);
    });
  });
}
