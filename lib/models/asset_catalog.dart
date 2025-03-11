import 'assets.dart';
import 'network.dart';

class AssetCatalog {
  AssetCatalog._();

  static final Map<String, Asset> _assets = {
    "btc": Asset(
      id: "btc",
      name: "Bitcoin",
      ticker: "BTC",
      precision: 8,
      network: Network.bitcoin,
      fiatPriceId: "bitcoin",
    ),
    "usdt": Asset(
      id: "usdt",
      name: "Tether USD",
      ticker: "USDT",
      precision: 8,
      network: Network.liquid,
      fiatPriceId: "tether",
      liquidAssetId:
          "ce091c998b83c78bb71a632313ba3760f1763d9cfcffae02258ffa9865a37bd2",
    ),
    "depix": Asset(
      id: "depix",
      name: "Depix",
      ticker: "DEPIX",
      precision: 8,
      network: Network.liquid,
      fiatPriceId: "depix",
      liquidAssetId:
          "02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189",
    ),
    "lbtc": Asset(
      id: "lbtc",
      name: "Liquid Bitcoin",
      ticker: "L-BTC",
      precision: 8,
      network: Network.liquid,
      fiatPriceId: "bitcoin",
      liquidAssetId:
          "6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d",
    ),
  };

  static final Map<String, Asset> _liquidAssetIdMap = Map.fromEntries(
    _assets.values
        .where((asset) => asset.liquidAssetId != null)
        .map((asset) => MapEntry(asset.liquidAssetId!, asset)),
  );

  static Asset? getById(String id) => _assets[id];
  static Asset? getByLiquidAssetId(String liquidAssetId) =>
      _liquidAssetIdMap[liquidAssetId];

  static List<Asset> get all => _assets.values.toList();

  static List<Asset> get liquidAssets =>
      _assets.values.where((asset) => asset.network == Network.liquid).toList();

  static Asset? get bitcoin => _assets["btc"];

  static List<OwnedAsset> defaultOwnedAssets() =>
      _assets.values.map((asset) => OwnedAsset.zero(asset)).toList();

  static List<OwnedAsset> defaultOwnedAssetsByNetwork(Network network) =>
      _assets.values
          .where((a) => a.network == network)
          .map((a) => OwnedAsset.zero(a))
          .toList();
}
