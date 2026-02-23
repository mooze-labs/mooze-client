import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/services/hybrid_price_service.dart';
import 'package:mooze_mobile/shared/prices/models/price_service_config.dart';
import 'package:mooze_mobile/shared/connectivity/providers/connectivity_provider.dart';

final connectedPriceServiceProvider = Provider<HybridPriceService>((ref) {
  return HybridPriceService(Currency.brl, PriceSource.coingecko);
});

extension ConnectivityIntegration on HybridPriceService {
  Future<void> getPriceWithConnectivityCheck(
    Asset asset,
    Ref ref, {
    Currency? optionalCurrency,
  }) async {
    final result =
        await getCoinPrice(asset, optionalCurrency: optionalCurrency).run();

    result.fold(
      (error) {
        hasCachedPrice(asset, optionalCurrency: optionalCurrency).run().then((
          cacheResult,
        ) {
          cacheResult.fold((error) => {}, (hasCache) {
            if (hasCache) {
              ref.read(connectivityProvider.notifier).markOffline();
            }
          });
        });
      },
      (priceOption) {
        priceOption.fold(
          () {
            hasCachedPrice(
              asset,
              optionalCurrency: optionalCurrency,
            ).run().then((cacheResult) {
              cacheResult.fold((error) => {}, (hasCache) {
                if (hasCache) {
                  ref.read(connectivityProvider.notifier).markOffline();
                }
              });
            });
          },
          (price) {
            ref.read(connectivityProvider.notifier).markOnline();
          },
        );
      },
    );
  }
}

final priceManagerProvider =
    StateNotifierProvider<PriceManager, Map<Asset, double?>>((ref) {
      return PriceManager(ref);
    });

class PriceManager extends StateNotifier<Map<Asset, double?>> {
  final Ref _ref;
  late final HybridPriceService _priceService;

  PriceManager(this._ref) : super({}) {
    _priceService = _ref.read(connectedPriceServiceProvider);
    _startPeriodicUpdates();
  }

  Future<void> updateAssetPrice(Asset asset) async {
    await _priceService.getPriceWithConnectivityCheck(asset, _ref);

    final result = await _priceService.getCoinPrice(asset).run();
    result.fold(
      (error) => {},
      (priceOption) => priceOption.fold(() => {}, (price) {
        state = {...state, asset: price};
      }),
    );
  }

  Future<void> updateAllPrices() async {
    final assets = [Asset.btc, Asset.usdt, Asset.depix];

    for (final asset in assets) {
      await updateAssetPrice(asset);
    }
  }

  void _startPeriodicUpdates() {
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted) {
        updateAllPrices().then((_) => _startPeriodicUpdates());
      }
    });
  }
}
