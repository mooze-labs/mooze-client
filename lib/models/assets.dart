enum Network { bitcoin, liquid }

class Asset {
  final String id;
  final String name;
  final String ticker;
  final int amount;
  final int precision;
  final Network network;
  final String logoPath;
  final String? coingeckoId;
  final String? assetId; // for blockchains that require assetId

  Asset({
    required this.id,
    required this.name,
    required this.ticker,
    required this.amount,
    required this.precision,
    required this.network,
    required this.logoPath,
    this.assetId = "",
    this.coingeckoId = "",
  });
}
