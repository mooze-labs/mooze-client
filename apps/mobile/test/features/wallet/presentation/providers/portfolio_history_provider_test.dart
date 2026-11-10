import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/asset_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/market_period.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/portfolio_history_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/models/price_service_config.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/prices/store/price_quote.dart';
import 'package:mooze_mobile/shared/prices/store/price_quotes_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Live prices without network or cache access.
class _FakeQuotes extends StateNotifier<PriceQuotes>
    implements PriceQuotesNotifier {
  _FakeQuotes(Map<Asset, double> prices)
    : super(
        PriceQuotes(
          currency: Currency.brl,
          quotes: {
            for (final MapEntry(key: asset, value: price) in prices.entries)
              asset: PriceQuote(
                asset: asset,
                currency: Currency.brl,
                price: price,
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
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// One whole coin in base units.
final _coin = BigInt.from(100000000);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Reads the 1D portfolio history of a wallet with [balances], 1D
  /// [histories] per asset, and live [prices].
  Future<AsyncValue<PortfolioHistory?>> read({
    required Map<Asset, BigInt> balances,
    Map<Asset, List<double>> histories = const {},
    Map<Asset, double> prices = const {},
  }) async {
    final container = ProviderContainer(
      overrides: [
        allAssetsProvider.overrideWithValue(const [Asset.btc, Asset.usdt]),
        allBalancesProvider.overrideWith((ref) async => balances),
        priceQuotesProvider.overrideWith((ref) => _FakeQuotes(prices)),
        currencyControllerProvider.overrideWith((ref) => _FakeCurrency()),
        priceHistoryFetcherProvider.overrideWithValue(
          (params) async => switch (histories[params.asset]) {
            final prices? => right(prices),
            null => left('offline'),
          },
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      portfolioHistoryProvider(MarketPeriod.day),
      (_, _) {},
    );
    for (var i = 0; i < 50 && subscription.read().isLoading; i++) {
      await pumpEventQueue();
    }
    return subscription.read();
  }

  test('sums balance × price per point, aligned from the last point', () async {
    final history = await read(
      balances: {Asset.btc: _coin, Asset.usdt: _coin * BigInt.two},
      histories: {
        Asset.btc: [10, 20, 30],
        // A longer history: only its last three points line up.
        Asset.usdt: [99, 5, 6, 7],
      },
    );

    expect(history.value!.values, [10 + 2 * 5, 20 + 2 * 6, 30 + 2 * 7]);
  });

  test('an asset without a history counts at its current price', () async {
    final history = await read(
      balances: {Asset.btc: _coin, Asset.usdt: _coin * BigInt.two},
      histories: {
        Asset.btc: [10, 20, 30],
      },
      prices: {Asset.usdt: 5},
    );

    expect(history.value!.values, [20, 30, 40]);
  });

  test('a wallet without holdings has no chart', () async {
    final history = await read(balances: {Asset.btc: BigInt.zero});

    expect(history.hasValue, isTrue);
    expect(history.value, isNull);
  });

  test('no history for any holding is an error', () async {
    final history = await read(
      balances: {Asset.btc: _coin},
      prices: {Asset.btc: 30},
    );

    expect(history.hasError, isTrue);
  });
}
