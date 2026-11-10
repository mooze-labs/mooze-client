import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/market_history_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/market_period.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/asset_row.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/percentage_variation_display.dart';
import 'package:mooze_mobile/shared/connectivity/providers/connectivity_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/models/price_service_config.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/shared/prices/store/price_quote.dart';
import 'package:mooze_mobile/shared/prices/store/price_quotes_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../shared/test_app.dart';

/// Quotes with the prices of [prices], as the store loads them from the
/// disk cache. No network.
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
                fetchedAt: DateTime(2026, 11, 7),
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

/// Whether the network is up, as the connectivity check reports it.
final _online = StateProvider<bool>((ref) => false);

void main() {
  /// The answer of the 24 h history service: an error while offline.
  late Either<String, List<double>> history;
  late int historyRequests;

  setUp(() {
    history = const Left('offline');
    historyRequests = 0;
    SharedPreferences.setMockInitialValues({});
  });

  /// Puts the 1D history of BTC on disk, as the market sheet stores it.
  void storeDayHistory(List<double> prices) {
    final key = MarketHistoryRepository.keyOf(
      Asset.btc,
      Currency.brl,
      MarketPeriod.day,
    );
    SharedPreferences.setMockInitialValues({
      'cached_price_history_$key': CachedPriceHistory(
        prices: prices,
        fetchedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ).toJsonString(),
    });
  }

  Future<ProviderContainer> show(
    WidgetTester tester, {
    Map<Asset, double> prices = const {Asset.btc: 500000},
  }) async {
    final container = ProviderContainer(
      overrides: [
        priceQuotesProvider.overrideWith((ref) => _FakeQuotes(prices)),
        currencyControllerProvider.overrideWith((ref) => _FakeCurrency()),
        assetPriceHistoryProvider.overrideWith((ref, asset) async {
          historyRequests++;
          return history;
        }),
        // The market sheet histories are offline too.
        priceHistoryFetcherProvider.overrideWithValue(
          (params) async => const Left('offline'),
        ),
        isOnlineProvider.overrideWith((ref) => ref.watch(_online)),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: wrapForTest(const Scaffold(body: AssetRow(asset: Asset.btc))),
      ),
    );
    // The row asks for the history after its first frame.
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('offline, the row shows the cached price, with no N/A', (
    tester,
  ) async {
    await show(tester);

    expect(find.text('R\$ 500.000,00'), findsOneWidget);
    // No history at all: the price stands alone, with no change pill.
    expect(find.text('N/A'), findsNothing);
    expect(find.byType(Sparkline), findsNothing);
    expect(find.byType(ChangeChip), findsNothing);
    expect(find.byType(UnavailableChangeChip), findsNothing);
  });

  testWidgets('offline, the row draws the 1D history kept on disk', (
    tester,
  ) async {
    storeDayHistory([480000, 490000, 500000]);
    await show(tester);

    expect(find.text('R\$ 500.000,00'), findsOneWidget);
    expect(find.byType(Sparkline), findsOneWidget);
    // 480 000 to 500 000: +4.17 %.
    expect(
      tester.widget<ChangeChip>(find.byType(ChangeChip)).percentage,
      closeTo(4.17, 0.01),
    );
    expect(find.text('N/A'), findsNothing);
  });

  testWidgets('with no price and no history, only the price reads N/A', (
    tester,
  ) async {
    await show(tester, prices: const {});

    expect(find.text('N/A'), findsOneWidget);
    expect(find.byType(UnavailableChangeChip), findsNothing);
    expect(find.textContaining('R\$'), findsNothing);
  });

  testWidgets('back online, the row loads its history again', (tester) async {
    final container = await show(tester);
    expect(find.byType(Sparkline), findsNothing);

    history = const Right([480000, 490000, 500000]);
    container.read(_online.notifier).state = true;
    await tester.pumpAndSettle();

    expect(historyRequests, 2);
    expect(find.byType(Sparkline), findsOneWidget);
    expect(find.byType(ChangeChip), findsOneWidget);
    expect(find.text('R\$ 500.000,00'), findsOneWidget);
  });
}
