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
}
