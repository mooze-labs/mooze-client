import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/swap/data/models.dart';
import 'package:mooze_mobile/features/swap/data/services/swap_onboarding_service.dart';
import 'package:mooze_mobile/features/swap/di/providers/peg_providers.dart';
import 'package:mooze_mobile/features/swap/di/providers/swap_repository_provider.dart';
import 'package:mooze_mobile/features/swap/domain/entities/peg.dart';
import 'package:mooze_mobile/features/swap/domain/repositories/swap_repository.dart';
import 'package:mooze_mobile/features/swap/presentation/screens/swap_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/bitcoin_fee_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/fee_speed_selector.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/connectivity/providers/connectivity_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/fake_core_sync_helpers.dart';
import 'fake_peg_orchestrator.dart';
import 'fixed_fee_provider.dart';
import 'peg_rule_core_sync_helpers.dart';

/// The market swaps are not under test here: no assets and no markets.
class _NoMarkets implements SwapRepository {
  @override
  TaskEither<String, List<SideswapAsset>> getAssets() =>
      TaskEither.right(const []);

  @override
  TaskEither<String, List<SideswapMarket>> getMarkets() =>
      TaskEither.right(const []);

  @override
  ({
    String baseAsset,
    String quoteAsset,
    SwapDirection direction,
    String assetType,
  })?
  normalizeSwapParams({
    required String sendAsset,
    required String receiveAsset,
  }) => null;

  @override
  Future<Either<String, Stream<QuoteResponse>>> startQuote({
    required String sendAsset,
    required String receiveAsset,
    required BigInt amount,
  }) async => const Left('no markets');

  @override
  Stream<QuoteResponse> get quoteStream => const Stream.empty();

  @override
  void stopQuote() {}

  @override
  Future<void> forceReconnect() async {}

  @override
  TaskEither<String, String> executeSwap(int quoteId) =>
      TaskEither.left('no markets');

  @override
  void dispose() {}
}

void main() {
  useCoreSyncHelpers(const PegRuleCoreSyncHelpers());

  late FakePegOrchestrator peg;

  setUp(() {
    peg = FakePegOrchestrator();
    SharedPreferences.setMockInitialValues({
      // The BTC / L-BTC warning was already seen.
      SwapOnboardingService.btcLbtcSwapWarningKey: true,
    });
  });

  /// [widthPt] defaults to the width of the phone in the bug report. The
  /// confirm sheet needs more: the test font draws each glyph as a full
  /// square.
  Future<void> open(WidgetTester tester, {double widthPt = 440}) async {
    tester.view.physicalSize = Size(widthPt * 3, 2868);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    // The analytics of the confirm sheet keep their state there.
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          swapRepositoryProvider.overrideWith((ref) async => _NoMarkets()),
          pegOrchestratorProvider.overrideWithValue(peg),
          pegLimitsProvider.overrideWith((ref) async => testPegLimits),
          bitcoinFeeServiceProvider.overrideWithValue(
            FixedFeeProvider().service,
          ),
          balanceProvider.overrideWith(
            (ref, asset) async => Right(
              BigInt.from(switch (asset) {
                Asset.btc => peg.bitcoinBalanceSat,
                Asset.lbtc => peg.liquidBalanceSat,
                _ => 0,
              }),
            ),
          ),
          fiatPriceProvider.overrideWith(
            (ref, asset) async => const Right(1.0),
          ),
          isUsingCacheProvider.overrideWithValue(false),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('pt'),
          builder: (context, child) =>
              Theme(data: AppTheme.lightTheme(context), child: child!),
          home: const SwapScreen(),
        ),
      ),
    );
    await settle(tester);
  }

  /// BTC → L-BTC: picks BTC as the asset to send.
  Future<void> pegIn(WidgetTester tester) async {
    await tester.tap(find.text('Depix').first);
    await settle(tester);
    await tester.tap(find.text('BTC').last);
    await settle(tester);
  }

  /// L-BTC → BTC: the peg-in, flipped.
  Future<void> pegOut(WidgetTester tester) async {
    await pegIn(tester);
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_SwapDirectionChip',
      ),
    );
    await settle(tester);
  }

  Future<void> type(WidgetTester tester, String sats) async {
    await tester.enterText(find.byType(TextField).first, sats);
    await settle(tester);
  }

  Future<void> tapMax(WidgetTester tester) async {
    await tester.tap(find.text('MAX'));
    await settle(tester);
  }

  final swapButton = find.ancestor(
    of: find.text('Swap'),
    matching: find.byType(PrimaryButton),
  );

  bool swapEnabled(WidgetTester tester) =>
      tester.widget<PrimaryButton>(swapButton).isEnabled;

  group('peg-out (L-BTC → BTC)', () {
    testWidgets('Max on 1 015 sats keeps Swap off and never opens the sheet', (
      tester,
    ) async {
      await open(tester);
      await pegOut(tester);

      await tapMax(tester);

      expect(swapEnabled(tester), isFalse);
      expect(find.text('Valor mínimo: 25.000 sats'), findsOneWidget);
      // The rules refused the balance: no quote was even asked for.
      expect(peg.quotes, isEmpty);
      await tester.tap(swapButton, warnIfMissed: false);
      await settle(tester);
      expect(find.text('Confirmar Swap'), findsNothing);
      expect(peg.executions, 0);
    });

    testWidgets('Max whose amount after the fee falls below 25 000 stays off', (
      tester,
    ) async {
      // The balance reaches the minimum, but the drain sends 24 990: only
      // the live quote of mooze-core sees it.
      peg = FakePegOrchestrator(liquidBalanceSat: 25010);
      await open(tester);
      await pegOut(tester);

      await tapMax(tester);

      expect(peg.quotes.last.drain, isTrue);
      expect(swapEnabled(tester), isFalse);
      expect(find.text('Valor mínimo: 25.000 sats'), findsOneWidget);
    });

    testWidgets('a typed amount below 25 000 sats keeps Swap off', (
      tester,
    ) async {
      await open(tester);
      await pegOut(tester);

      await type(tester, '24999');

      expect(swapEnabled(tester), isFalse);
      expect(find.text('Valor mínimo: 25.000 sats'), findsOneWidget);
    });

    testWidgets('Swap opens the sheet on the live quote, with no new one', (
      tester,
    ) async {
      peg = FakePegOrchestrator(liquidBalanceSat: 50000);
      await open(tester, widthPt: 600);
      await pegOut(tester);
      await type(tester, '30000');
      final asked = peg.quotes.length;

      await tester.tap(swapButton);
      await settle(tester);

      expect(peg.quotes.length, asked);
      // The total of the screen and of the sheet: 20 plus 30.
      expect(find.text('Total de taxas: 50 sats'), findsOneWidget);
      expect(find.text('50 sats'), findsOneWidget);
    });
  });

  group('peg-in (BTC → L-BTC)', () {
    testWidgets('a typed amount below 10 000 sats keeps Swap off', (
      tester,
    ) async {
      await open(tester);
      await pegIn(tester);

      await type(tester, '5000');

      expect(swapEnabled(tester), isFalse);
      expect(find.text('Valor mínimo: 10.000 sats'), findsOneWidget);
    });

    testWidgets('a valid amount shows its live quote before Swap', (
      tester,
    ) async {
      await open(tester);
      await pegIn(tester);

      await type(tester, '30000');

      expect(peg.quotes.last.amountSat, BigInt.from(30000));
      expect(peg.quotes.last.direction, PegDirection.pegIn);
      // Priced at the normal 5 sat/vB: 30 000 less the network fee of 500
      // and the service fee of 30.
      expect(peg.quotes.last.feeRateSatPerVByte, 5);
      expect(find.text('29.470'), findsOneWidget);
      expect(swapEnabled(tester), isTrue);
    });

    testWidgets('Max quotes a drain and shows what arrives', (tester) async {
      await open(tester);
      await pegIn(tester);

      await tapMax(tester);

      expect(peg.quotes.last.drain, isTrue);
      // The drain sends 66 734 (67 234 less the network fee of 500). The
      // estimate takes the network fee of 500 and the service fee of 67.
      expect(find.text('66.167'), findsOneWidget);
      expect(swapEnabled(tester), isTrue);
    });

    testWidgets('Swap opens the sheet on the live quote, with no new one', (
      tester,
    ) async {
      await open(tester, widthPt: 600);
      await pegIn(tester);
      await type(tester, '30000');
      final asked = peg.quotes.length;

      await tester.tap(swapButton);
      await settle(tester);

      // The sheet is open, with no economic speed.
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Econômica'), findsNothing);
      expect(peg.quotes.length, asked);
      // The total of the screen and of the sheet: 500 plus 30.
      expect(find.text('Total de taxas: 530 sats'), findsOneWidget);
      expect(find.text('530 sats'), findsOneWidget);
    });

    testWidgets('with the economy fee on, screen and sheet use it', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        SwapOnboardingService.btcLbtcSwapWarningKey: true,
        'pegLowFeeEnabled': true,
      });
      await open(tester, widthPt: 600);
      await pegIn(tester);
      await type(tester, '30000');

      expect(peg.quotes.last.feeRateSatPerVByte, 2);
      expect(find.text('Total de taxas: 230 sats'), findsOneWidget);

      await tester.tap(swapButton);
      await settle(tester);

      expect(
        tester
            .widget<FeeSpeedSelector>(find.byType(FeeSpeedSelector))
            .selectedSpeed,
        FeeSpeed.low,
      );
      // 2 sat/vB × 100 vB plus 30, on the screen and on the sheet.
      expect(find.text('230 sats'), findsOneWidget);
    });
  });
}

/// Pumps frames for the debounce, the quote and the shimmer. The screen
/// animates without end, so `pumpAndSettle` would not return.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
