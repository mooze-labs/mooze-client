import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:shared_preferences/shared_preferences.dart';

final allAssetsProvider = Provider<List<Asset>>((ref) {
  return const [Asset.btc, Asset.usdt, Asset.depix, Asset.lbtc];
});

final assetsForQuotesProvider = Provider<List<Asset>>((ref) {
  return const [Asset.btc, Asset.usdt, Asset.depix];
});

final favoriteAssetsProvider =
    StateNotifierProvider<FavoriteAssetsNotifier, List<Asset>>((ref) {
      return FavoriteAssetsNotifier();
    });

final isFavoriteAssetProvider = Provider.family<bool, Asset>((ref, asset) {
  final favoriteAssets = ref.watch(favoriteAssetsProvider);
  return favoriteAssets.contains(asset);
});

class FavoriteAssetsNotifier extends StateNotifier<List<Asset>> {
  static const String _favoritesKey = 'favorite_assets';

  FavoriteAssetsNotifier() : super([]) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteStrings = prefs.getStringList(_favoritesKey);

      if (favoriteStrings != null) {
        final favorites =
            favoriteStrings
                .map((assetName) => _assetFromString(assetName))
                .where((asset) => asset != null)
                .cast<Asset>()
                .toList();
        state = favorites.take(2).toList();
      } else {
        state = const [Asset.btc, Asset.usdt];
        await _saveFavorites();
      }
    } catch (e) {
      state = const [Asset.btc, Asset.usdt];
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteStrings = state.map((asset) => asset.name).toList();
      await prefs.setStringList(_favoritesKey, favoriteStrings);
    } catch (e) {
      // In case of an error, it continues running only in memory.
    }
  }

  Asset? _assetFromString(String assetName) {
    switch (assetName.toLowerCase()) {
      case 'bitcoin':
        return Asset.btc;
      case 'usdt':
        return Asset.usdt;
      case 'decentralized pix':
        return Asset.depix;
      case 'bitcoin l2':
        return Asset.lbtc;
      default:
        return null;
    }
  }

  void toggleFavorite(Asset asset) async {
    final currentFavorites = state;
    if (currentFavorites.contains(asset)) {
      state = currentFavorites.where((a) => a != asset).toList();
    } else {
      if (currentFavorites.length < 2) {
        state = [...currentFavorites, asset];
      } else {
        state = [currentFavorites[1], asset];
      }
    }
    await _saveFavorites();
  }

  void setFavorites(List<Asset> assets) async {
    state = assets.take(2).toList();
    await _saveFavorites();
  }
}
