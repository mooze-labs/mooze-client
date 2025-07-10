/// Asset information returned by the assets API
class SideswapAsset {
  final String assetId;
  final bool? alwaysShow;
  final Map<String, dynamic>? contract;
  final String? domain;
  final String? iconUrl;
  final bool? instantSwaps;
  final Map<String, dynamic>? issuancePrevout;
  final String? issuerPubkey;
  final String? marketType;
  final String name;
  final bool? payjoin;
  final int precision;
  final String ticker;

  SideswapAsset({
    required this.assetId,
    this.alwaysShow,
    this.contract,
    this.domain,
    this.iconUrl,
    this.instantSwaps,
    this.issuancePrevout,
    this.issuerPubkey,
    this.marketType,
    required this.name,
    this.payjoin,
    required this.precision,
    required this.ticker,
  });

  factory SideswapAsset.fromJson(Map<String, dynamic> json) {
    return SideswapAsset(
      assetId: json['asset_id'],
      alwaysShow: json['always_show'],
      contract: json['contract'],
      domain: json['domain'],
      iconUrl: json['icon_url'],
      instantSwaps: json['instant_swaps'],
      issuancePrevout: json['issuance_prevout'],
      issuerPubkey: json['issuer_pubkey'],
      marketType: json['market_type'],
      name: json['name'],
      payjoin: json['payjoin'],
      precision: json['precision'],
      ticker: json['ticker'],
    );
  }
}
