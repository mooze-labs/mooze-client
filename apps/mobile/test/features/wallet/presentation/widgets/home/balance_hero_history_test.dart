import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/asset_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/market_history_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/market_period.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/portfolio_history_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/visibility_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_total_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/asset_market/market_chart.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/holding_asset/portfolio_history_sheet.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/balance_hero.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/percentage_variation_display.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/models/price_service_config.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/prices/store/price_quote.dart';
import 'package:mooze_mobile/shared/prices/store/price_quotes_notifier.dart';
import 'package:mooze_mobile/themes/app_extra_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A live BTC price of 30, without network or cache access.
class _FakeQuotes extends StateNotifier<PriceQuotes>
    implements PriceQuotesNotifier {
  _FakeQuotes()
    : super(
        PriceQuotes(
          currency: Currency.brl,
          quotes: {
            Asset.btc: PriceQuote(
              asset: Asset.btc,
              currency: Currency.brl,
              price: 30,
              fetchedAt: DateTime(2026, 11, 1),
            ),
          },
          lastSuccessAt: null,
          warming: false,
          refreshing: false,
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Currency without storage access.
class _FakeCurrency extends StateNotifier<Currency>
    implements CurrencyNotifier {
  _FakeCurrency() : super(Currency.brl);

  @override
  String get icon => 'R\$';

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Balance visibility without storage access.
class _FakeVisibility extends StateNotifier<bool>
    implements VisibilityNotifier {
  _FakeVisibility() : super(false);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  /// History requests, while the network is down.
  late List<AssetPriceHistoryParams> requests;

  setUp(() => requests = []);

  /// Stores a 1D BTC history on the disk, [age] old.
  void cacheDay({Duration age = const Duration(minutes: 10)}) {
    final key = MarketHistoryRepository.keyOf(
      Asset.btc,
      Currency.brl,
      MarketPeriod.day,
    );
    SharedPreferences.setMockInitialValues({
      'cached_price_history_$key': CachedPriceHistory(
        prices: [10, 20, 30],
        fetchedAt: DateTime.now().subtract(age),
      ).toJsonString(),
    });
  }

  /// The connected hero of one BTC, with [onVariationTap].
  Future<void> pump(
    WidgetTester tester, {
    void Function(BuildContext origin)? onVariationTap,
  }) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allAssetsProvider.overrideWithValue(const [Asset.btc]),
          allBalancesProvider.overrideWith(
            (ref) async => {Asset.btc: BigInt.from(100000000)},
          ),
          priceQuotesProvider.overrideWith((ref) => _FakeQuotes()),
          currencyControllerProvider.overrideWith((ref) => _FakeCurrency()),
          isVisibleProvider.overrideWith((ref) => _FakeVisibility()),
          totalWalletValueProvider.overrideWithValue(
            AsyncValue.data(right(30)),
          ),
          totalWalletVariationProvider.overrideWithValue(
            AsyncValue.data(right(0.08)),
          ),
          priceHistoryFetcherProvider.overrideWithValue((params) async {
            requests.add(params);
            return left('offline');
          }),
        ],
        child: MaterialApp.router(
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData.dark().copyWith(
            extensions: const [AppExtraColors.dark],
          ),
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => Scaffold(
                  body: Padding(
                    padding: const EdgeInsets.all(20),
                    child: BalanceHero(onVariationTap: onVariationTap),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    // The balances and the stored histories load.
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
  }

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(BalanceHero)));

  testWidgets('the hero computes the 1D history before the chip is tapped, '
      'and the sheet opens on that chart', (tester) async {
    cacheDay();
    await pump(tester, onVariationTap: showPortfolioHistorySheet);
    expect(
      container(tester).read(portfolioHistoryProvider(MarketPeriod.day)).value,
      isA<PortfolioHistory>().having((h) => h.values, 'values', [10, 20, 30]),
    );

    await tester.tap(find.byType(ChangeChip));
    await tester.pump();
    await tester.pump();

    expect(find.byType(MarketChart), findsOneWidget);
    expect(find.byType(MarketChartLoading), findsNothing);
  });

  testWidgets('opening the sheet refreshes a history older than the reopen '
      'gap', (tester) async {
    cacheDay();
    await pump(tester, onVariationTap: showPortfolioHistorySheet);
    final before = requests.length;

    await tester.tap(find.byType(ChangeChip));
    await tester.pump();
    await tester.pump();

    expect(requests.skip(before).map((r) => r.asset), [Asset.btc]);
    // Offline, the chart keeps its history.
    expect(find.byType(MarketChart), findsOneWidget);
  });

  testWidgets('opening the sheet keeps a history younger than the reopen '
      'gap', (tester) async {
    cacheDay(age: Duration.zero);
    await pump(tester, onVariationTap: showPortfolioHistorySheet);

    await tester.tap(find.byType(ChangeChip));
    await tester.pump();
    await tester.pump();

    expect(requests, isEmpty);
    expect(find.byType(MarketChart), findsOneWidget);
  });

  testWidgets('without a chip callback, the hero computes no history', (
    tester,
  ) async {
    cacheDay();
    await pump(tester);

    expect(requests, isEmpty);
  });
}
