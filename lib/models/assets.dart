enum Network { bitcoin, liquid }

class Asset {
  final String id;
  final String name;
  final String ticker;
  final int amount;
  final int precision;
  final Network network;
  final String logoPath;
  final String? fiatPriceId;
  final String? liquidAssetId; // for liquid network

  Asset({
    required this.id,
    required this.name,
    required this.ticker,
    required this.amount,
    required this.precision,
    required this.network,
    required this.logoPath,
    this.liquidAssetId = "",
    this.fiatPriceId = "",
  });
}
