import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

final allAssetsProvider = Provider<List<Asset>>((ref) {
  return const [Asset.btc, Asset.lbtc, Asset.usdt, Asset.depix];
});

final favoriteAssetsProvider = StateProvider<List<Asset>>((ref) {
  return const [Asset.btc, Asset.usdt];
});

final isFavoriteAssetProvider = Provider.family<bool, Asset>((ref, asset) {
  final favoriteAssets = ref.watch(favoriteAssetsProvider);
  return favoriteAssets.contains(asset);
});

extension FavoriteAssetsNotifier on StateController<List<Asset>> {
  void toggleFavorite(Asset asset) {
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
  }

  void setFavorites(List<Asset> assets) {
    // Limita a 2 ativos favoritos
    state = assets.take(2).toList();
  }
}
