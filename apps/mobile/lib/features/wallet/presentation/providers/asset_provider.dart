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

/// The assets pinned to the home screen, in the order the home screen shows
/// them: at least one, at most two.
class FavoriteAssetsNotifier extends StateNotifier<List<Asset>> {
  static const String _favoritesKey = 'favorite_assets';

  /// Pinned assets of a new install, and of an install that saved none.
  static const List<Asset> _defaults = [Asset.btc, Asset.usdt];

  FavoriteAssetsNotifier() : super([]) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteStrings = prefs.getStringList(_favoritesKey);

      final favorites = (favoriteStrings ?? const <String>[])
          .map((assetName) => _assetFromString(assetName))
          .whereType<Asset>()
          .toList();
      if (favorites.isNotEmpty) {
        state = favorites.take(2).toList();
      } else {
        // Nothing saved, or an empty list from a version that allowed it:
        // the home screen shows at least one asset.
        state = _defaults;
        await _saveFavorites();
      }
    } catch (e) {
      state = _defaults;
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
      case 'liquid bitcoin':
      // The name of L-BTC in earlier versions.
      case 'bitcoin l2':
        return Asset.lbtc;
      default:
        return null;
    }
  }

  /// Pins [asset], or unpins it. The last pinned asset stays: the home
  /// screen shows at least one. A third pin takes the place of the second,
  /// so the first stays first.
  void toggleFavorite(Asset asset) async {
    final currentFavorites = state;
    if (currentFavorites.contains(asset)) {
      if (currentFavorites.length <= 1) return;
      state = currentFavorites.where((a) => a != asset).toList();
    } else {
      if (currentFavorites.length < 2) {
        state = [...currentFavorites, asset];
      } else {
        state = [currentFavorites[0], asset];
      }
    }
    await _saveFavorites();
  }

  /// Sets the pinned assets in the order of [assets], for example after a
  /// drag. An empty list is ignored: the home screen shows at least one.
  void setFavorites(List<Asset> assets) async {
    if (assets.isEmpty) return;
    state = assets.take(2).toList();
    await _saveFavorites();
  }
}
