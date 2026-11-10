import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/cached_data_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/fiat_price_provider.dart';
import 'package:mooze_mobile/shared/connectivity/providers/connectivity_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

/// Whether the network is up, as the connectivity check reports it.
final _online = StateProvider<bool>((ref) => true);

const _klines = Right<String, List<double>>([480000, 490000, 500000]);
const _offline = Left<String, List<double>>('offline');

void main() {
  /// The answer of the 24 h history service.
  late Either<String, List<double>> history;
  late int requests;

  setUp(() {
    history = _klines;
    requests = 0;
  });

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        assetPriceHistoryProvider.overrideWith((ref, asset) async {
          requests++;
          return history;
        }),
        isOnlineProvider.overrideWith((ref) => ref.watch(_online)),
      ],
    );
    addTearDown(c.dispose);
    // Keeps the cache alive, as the home rows do.
    c.listen(assetPriceHistoryCacheProvider, (_, _) {});
    return c;
  }

  Either<String, List<double>>? btcHistory(ProviderContainer c) =>
      c.read(cachedAssetPriceHistoryProvider(Asset.btc));

  AssetPriceHistoryNotifier notifier(ProviderContainer c) =>
      c.read(assetPriceHistoryCacheProvider.notifier);

  test('a refresh that fails keeps the history it had', () async {
    final c = container();
    await notifier(c).fetchAssetPriceHistory(Asset.btc);

    history = _offline;
    await notifier(c).refresh([Asset.btc]);

    expect(btcHistory(c), _klines);
  });

  test('a refresh loads again a history that failed', () async {
    history = _offline;
    final c = container();
    await notifier(c).fetchAssetPriceHistory(Asset.btc);
    expect(btcHistory(c)!.isLeft(), isTrue);

    history = _klines;
    await notifier(c).refresh([Asset.btc]);

    expect(btcHistory(c), _klines);
  });

  test('a forced refresh asks once per asset', () async {
    final c = container();
    await notifier(c).fetchAssetPriceHistory(Asset.btc);

    await notifier(c).refresh([Asset.btc]);
    await notifier(c).fetchAssetPriceHistory(Asset.btc, forceRefresh: true);

    expect(requests, 3);
  });

  test('back online, only the histories that failed load again', () async {
    final c = container();
    await notifier(c).fetchAssetPriceHistory(Asset.lbtc);
    history = _offline;
    c.read(_online.notifier).state = false;
    await notifier(c).fetchAssetPriceHistory(Asset.btc);
    expect(requests, 2);

    history = _klines;
    c.read(_online.notifier).state = true;
    await pumpEventQueue();

    expect(requests, 3);
    expect(btcHistory(c), _klines);
    expect(c.read(cachedAssetPriceHistoryProvider(Asset.lbtc)), _klines);
  });
}
