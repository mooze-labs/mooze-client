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
}
