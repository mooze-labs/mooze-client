/// Represents a market on the Sideswap platform
class SideswapMarket {
  final String baseAssetId;
  final String quoteAssetId;
  final String feeAsset; // "Base" or "Quote"
  final String type; // "Stablecoin", "Amp", "Token"

  SideswapMarket({
    required this.baseAssetId,
    required this.quoteAssetId,
    required this.feeAsset,
    required this.type,
  });

  factory SideswapMarket.fromJson(Map<String, dynamic> json) {
    final assetPair = json['asset_pair'];
    return SideswapMarket(
      baseAssetId: assetPair['base'],
      quoteAssetId: assetPair['quote'],
      feeAsset: json['fee_asset'],
      type: json['type'],
    );
  }
}
