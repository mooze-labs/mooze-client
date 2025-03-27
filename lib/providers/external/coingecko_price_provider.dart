import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'coingecko_price_provider.g.dart';

class CoingeckoAssetPairs {
  final List<String> assets;
  final String baseCurrency;

  CoingeckoAssetPairs({required this.assets, required this.baseCurrency});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoingeckoAssetPairs &&
        other.baseCurrency == baseCurrency &&
        listEquals(other.assets, assets);
  }

  @override
  int get hashCode => Object.hash(assets, baseCurrency);
}

// Helper function to compare lists
bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

// Class to hold cached prices with a timestamp
class CachedPrices {
  final Map<String, double> prices;
  final DateTime timestamp;

  CachedPrices(this.prices, this.timestamp);

  bool get isStale => DateTime.now().difference(timestamp).inMinutes >= 2;
}

@Riverpod(keepAlive: true)
class CoinGeckoPriceCache extends _$CoinGeckoPriceCache {
  Timer? _refreshTimer;
  bool _initialized = false;

  @override
  Future<CachedPrices> build() async {
    // Cancel the timer when the provider is disposed
    ref.onDispose(() {
      _refreshTimer?.cancel();
    });

    // Return an empty cache initially
    // The actual data will be loaded on first access
    return CachedPrices({}, DateTime.now().subtract(Duration(minutes: 5)));
  }

  // Method to force immediate synchronization
  Future<Map<String, double>> syncNow(CoingeckoAssetPairs params) async {
    try {
      // Fetch prices with the provided parameters
      final newPrices = await _fetchCoingeckoPrices(params);

      // Update the state with fresh data
      state = AsyncValue.data(CachedPrices(newPrices, DateTime.now()));

      // Set up the periodic timer if not already initialized
      if (!_initialized) {
        _setupPeriodicSync(params);
        _initialized = true;
      }

      return newPrices;
    } catch (e, stackTrace) {
      // On error, update state to error
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  void _setupPeriodicSync(CoingeckoAssetPairs params) {
    // Set up a timer to refresh every 2 minutes
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _refreshPrices(params),
    );
  }

  Future<void> _refreshPrices(CoingeckoAssetPairs params) async {
    try {
      // Fetch new prices
      final newPrices = await _fetchCoingeckoPrices(params);

      // Update the state with fresh data
      state = AsyncValue.data(CachedPrices(newPrices, DateTime.now()));
    } catch (e, stackTrace) {
      // On error, don't update the state to preserve the previous data
      debugPrint("Error refreshing prices: $e - $stackTrace");
    }
  }
}

@riverpod
Future<Map<String, double>> coingeckoPrice(
  Ref ref,
  CoingeckoAssetPairs coingeckoAssetPairs,
) async {
  // Get the cache
  final cacheNotifier = ref.read(coinGeckoPriceCacheProvider.notifier);
  final cacheData = ref.watch(coinGeckoPriceCacheProvider);

  // Use cache data if it exists and isn't stale
  return cacheData.when(
    data: (cache) {
      if (cache.prices.isNotEmpty && !cache.isStale) {
        return cache.prices;
      } else {
        // Force sync on first request or when cache is stale
        return cacheNotifier.syncNow(coingeckoAssetPairs);
      }
    },
    loading: () => cacheNotifier.syncNow(coingeckoAssetPairs),
    error: (_, __) => cacheNotifier.syncNow(coingeckoAssetPairs),
  );
}

Future<Map<String, double>> _fetchCoingeckoPrices(
  CoingeckoAssetPairs assetPairs,
) async {
  if (assetPairs.assets.isEmpty) {
    return {};
  }

  final uri = Uri.https("api.coingecko.com", "/api/v3/simple/price", {
    "ids": assetPairs.assets.join(","),
    "vs_currencies": assetPairs.baseCurrency.toLowerCase(),
  });

  final response = await http.get(uri);
  if (response.statusCode != 200) {
    throw Exception(
      "[ERROR] Failed to fetch prices: ${response.statusCode} - ${response.reasonPhrase}",
    );
  }

  debugPrint("Fetched prices from Coingecko");
  final json = jsonDecode(response.body) as Map<String, dynamic>;
  return json.map(
    (id, data) => MapEntry(
      id,
      (data[assetPairs.baseCurrency.toLowerCase()] as num).toDouble(),
    ),
  );
}
