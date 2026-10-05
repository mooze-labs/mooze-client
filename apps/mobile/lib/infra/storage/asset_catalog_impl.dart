import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_catalog.dart';

/// Static catalog mirroring legacy `allAssetsProvider` / `assetsForQuotesProvider`.
class StaticAssetCatalog implements AssetCatalog {
  const StaticAssetCatalog();

  @override
  List<Asset> get allAssets => const [
        Asset.btc,
        Asset.usdt,
        Asset.depix,
        Asset.lbtc,
      ];

  @override
  List<Asset> get assetsForQuotes => const [
        Asset.btc,
        Asset.usdt,
        Asset.depix,
      ];
}

/// SharedPreferences-backed favourites store. Same key + clamp-to-2 semantics
/// as legacy `FavoriteAssetsNotifier` so users keep their existing pin choice
/// across the migration cutover.
class SharedPreferencesFavouriteAssetsStore implements FavouriteAssetsStore {
  SharedPreferencesFavouriteAssetsStore({
    SharedPreferences? prefs,
    this.preferencesKey = 'favorite_assets',
    this.maxFavourites = 2,
  }) : _injectedPrefs = prefs;

  final SharedPreferences? _injectedPrefs;
  final String preferencesKey;
  final int maxFavourites;

  Future<SharedPreferences> _prefs() async =>
      _injectedPrefs ?? await SharedPreferences.getInstance();

  @override
  Future<List<Asset>> load() async {
    try {
      final p = await _prefs();
      final stored = p.getStringList(preferencesKey);
      if (stored == null) {
        // Legacy default: BTC + USDT pinned on first launch.
        return const [Asset.btc, Asset.usdt];
      }
      final resolved = stored
          .map(_assetFromLegacyName)
          .whereType<Asset>()
          .take(maxFavourites)
          .toList();
      if (resolved.isEmpty) {
        return const [Asset.btc, Asset.usdt];
      }
      return resolved;
    } catch (_) {
      return const [Asset.btc, Asset.usdt];
    }
  }

  @override
  Future<void> save(List<Asset> favourites) async {
    try {
      final p = await _prefs();
      final clipped = favourites.take(maxFavourites).toList();
      await p.setStringList(
        preferencesKey,
        // Stored as `Asset.name` (e.g. 'btc', 'usdt') which is what
        // SharedPreferences already holds for legacy installs writing via
        // `asset.name`. The legacy notifier actually wrote `asset.name` (enum
        // name), NOT the display name — `_assetFromLegacyName` handles both
        // for compatibility.
        clipped.map((a) => a.name).toList(),
      );
    } catch (_) {
      // Persistence failure is non-fatal; favourites stay in memory.
    }
  }

  /// Compat layer: legacy wrote `asset.name` ('btc') in some builds and
  /// `asset.displayName` ('Bitcoin') in others. Accept both.
  Asset? _assetFromLegacyName(String stored) {
    final s = stored.trim().toLowerCase();
    return switch (s) {
      'btc' || 'bitcoin' => Asset.btc,
      'lbtc' || 'bitcoin l2' || 'btc l2' => Asset.lbtc,
      'usdt' || 'usdt liquid' || 'tether' => Asset.usdt,
      'depix' || 'decentralized pix' => Asset.depix,
      _ => null,
    };
  }
}
