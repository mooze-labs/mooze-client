import 'asset.dart';

/// The full list of assets the wallet supports, plus the user's favourites
/// subset. Pulled out of presentation (legacy `allAssetsProvider` /
/// `favoriteAssetsProvider`) so use-cases and repositories can depend on the
/// catalog without dragging in the SharedPreferences-backed favourites store.
///
/// Implementations live in infra (`infra/storage/asset_catalog_impl.dart`).
abstract interface class AssetCatalog {
  /// All assets the app exposes. Stable across boots; legacy returns
  /// `[btc, usdt, depix, lbtc]` in that order.
  List<Asset> get allAssets;

  /// Subset of [allAssets] used for fast quote lookups (e.g. price feed
  /// preloads). Legacy: `[btc, usdt, depix]`.
  List<Asset> get assetsForQuotes;
}

/// Opt-in user state — which assets the user pinned to the home screen.
/// Persisted in shared preferences in legacy; ported as-is.
abstract interface class FavouriteAssetsStore {
  Future<List<Asset>> load();

  /// Persist the new favourites list. Legacy caps at 2; V2 preserves that
  /// cap by clamping inside the implementation, not at the call site.
  Future<void> save(List<Asset> favourites);
}
