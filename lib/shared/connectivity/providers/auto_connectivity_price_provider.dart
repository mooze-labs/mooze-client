import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/services/hybrid_price_service.dart';
import 'package:mooze_mobile/shared/prices/models/price_service_config.dart';
import 'package:mooze_mobile/shared/connectivity/providers/connectivity_provider.dart';

/// Main provider for HybridPriceService
final hybridPriceServiceProvider = Provider<HybridPriceService>((ref) {
  return HybridPriceService(Currency.brl, PriceSource.coingecko);
});

/// Provider that manages prices with automatic connectivity detection
final autoConnectivityPriceProvider =
    StateNotifierProvider<AutoConnectivityPriceNotifier, Map<Asset, double?>>((
      ref,
    ) {
      return AutoConnectivityPriceNotifier(ref);
    });

/// StateNotifier that updates prices and detects connectivity automatically
class AutoConnectivityPriceNotifier extends StateNotifier<Map<Asset, double?>> {
  final Ref _ref;
  late final HybridPriceService _priceService;

  AutoConnectivityPriceNotifier(this._ref) : super({}) {
    _priceService = _ref.read(hybridPriceServiceProvider);
    _startAutoUpdate();
  }

  /// Starts automatic updates every 60 seconds
  void _startAutoUpdate() {
    Future.delayed(const Duration(seconds: 60), () {
      if (mounted) {
        updateAllPrices().then((_) => _startAutoUpdate());
      }
    });
  }

  /// Updates the price of a specific asset with connectivity detection
  Future<void> updateAssetPrice(Asset asset) async {
    try {
      final result =
          await _priceService
              .getCoinPriceWithConnectivityUpdate(asset, ref: _ref)
              .run();

      result.fold(
        (error) {
          // Error - try to use cache if available
          _tryLoadFromCache(asset);
        },
        (priceOption) => priceOption.fold(
          () {
            // No price, try cache
            _tryLoadFromCache(asset);
          },
          (price) {
            // Success - update state
            state = {...state, asset: price};
          },
        ),
      );
    } catch (e) {
      // In case of error, try to load from cache
      _tryLoadFromCache(asset);
    }
  }

  /// Attempts to load price from cache when API fails
  Future<void> _tryLoadFromCache(Asset asset) async {
    final cacheResult = await _priceService.getCoinPrice(asset).run();
    cacheResult.fold(
      (error) => {}, // Nothing to do
      (priceOption) => priceOption.fold(
        () => {}, // No cache available
        (price) {
          // Cache available - use it and mark as offline
          state = {...state, asset: price};
          _ref.read(connectivityProvider.notifier).markOffline();
        },
      ),
    );
  }

  /// Updates all main assets
  Future<void> updateAllPrices() async {
    final assets = [Asset.btc, Asset.usdt, Asset.depix];

    // Update in parallel
    await Future.wait(assets.map((asset) => updateAssetPrice(asset)));
  }

  /// Forces a manual update
  Future<void> forceRefresh() async {
    await updateAllPrices();
  }

  /// Gets the price of a specific asset
  double? getPriceFor(Asset asset) {
    return state[asset];
  }
}

/// Provider that returns the price of a specific asset
final assetPriceProvider = Provider.family<double?, Asset>((ref, asset) {
  final prices = ref.watch(autoConnectivityPriceProvider);
  return prices[asset];
});

/// Provider that forces a manual price refresh
final manualPriceRefreshProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    await ref.read(autoConnectivityPriceProvider.notifier).forceRefresh();
  };
});

/// Provider that indicates whether any price is currently loading
final pricesLoadingProvider = Provider<bool>((ref) {
  final prices = ref.watch(autoConnectivityPriceProvider);
  return prices.isEmpty;
});
