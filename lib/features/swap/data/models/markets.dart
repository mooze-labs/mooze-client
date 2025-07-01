class Market {
  final String baseAsset;
  final String quoteAsset;
  final String feeAsset;
  final String type;

  Market({
    required this.baseAsset,
    required this.quoteAsset,
    required this.feeAsset,
    required this.type,
  });

  factory Market.fromJson(Map<String, dynamic> json) {
    return Market(
      baseAsset: json['base'],
      quoteAsset: json['quote'],
      feeAsset: json['fee_asset'],
      type: json['type'],
    );
  }
}
