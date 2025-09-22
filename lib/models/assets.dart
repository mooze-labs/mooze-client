import 'asset_catalog.dart';
import 'network.dart';

import 'package:mooze_mobile/services/liquid.dart';

class Asset {
  final String id;
  final String name;
  final String ticker;
  final int precision;
  final Network network;
  final String? fiatPriceId;
  final String? liquidAssetId; // for liquid network

  Asset({
    required this.id,
    required this.name,
    required this.ticker,
    required this.precision,
    required this.network,
    this.liquidAssetId = "",
    this.fiatPriceId = "",
  });
}

class OwnedAsset {
  final Asset asset;
  final int amount;
  final DateTime lastUpdated;
  final bool mainnet;

  OwnedAsset({
    required this.asset,
    required this.amount,
    DateTime? lastUpdated,
    this.mainnet = true,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory OwnedAsset.zero(Asset asset) {
    return OwnedAsset(asset: asset, amount: 0);
  }

  static Future<OwnedAsset> liquid({
    required String assetId,
    required int amount,
    bool mainnet = true,
  }) async {
    Asset? asset = AssetCatalog.getByLiquidAssetId(assetId);

    if (asset != null) {
      return OwnedAsset(asset: asset, amount: amount, mainnet: mainnet);
    }

    final liquidAssetService = LiquidAssetService();
    final assetInfo = await liquidAssetService.fetchAsset(assetId, mainnet);

    if (assetInfo == null) {
      return OwnedAsset(
        asset: Asset(
          id: "unknownliquidasset",
          name: "Unknown Liquid Asset",
          network: Network.liquid,
          precision: 0,
          ticker: "UNK",
        ),
        amount: amount,
      );
    }

    asset = Asset(
      id: assetInfo.name.toLowerCase().replaceAll(" ", "-"),
      name: assetInfo.name,
      network: Network.liquid,
      precision: assetInfo.precision,
      ticker: assetInfo.ticker,
    );

    return OwnedAsset(asset: asset, amount: amount);
  }

  static OwnedAsset bitcoin(int amount) {
    return OwnedAsset(asset: AssetCatalog.bitcoin!, amount: amount);
  }
}
