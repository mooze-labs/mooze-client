/// A successful quote from the Sideswap API
class SideswapQuote {
  final int quoteId;
  final int baseAmount;
  final int quoteAmount;
  final int serverFee;
  final int fixedFee;
  final int ttl;

  SideswapQuote({
    required this.quoteId,
    required this.baseAmount,
    required this.quoteAmount,
    required this.serverFee,
    required this.fixedFee,
    required this.ttl,
  });

  factory SideswapQuote.fromJson(Map<String, dynamic> json) {
    final success = json['status']['Success'];
    return SideswapQuote(
      quoteId: success['quote_id'],
      baseAmount: success['base_amount'],
      quoteAmount: success['quote_amount'],
      serverFee: success['server_fee'],
      fixedFee: success['fixed_fee'],
      ttl: success['ttl'],
    );
  }
}
