class Quote {
  final int quoteId;
  final BigInt baseAmount;
  final BigInt quoteAmount;
  final BigInt serverFee;
  final BigInt fixedFee;
  final int ttl;

  Quote({
    required this.quoteId,
    required this.baseAmount,
    required this.quoteAmount,
    required this.serverFee,
    required this.fixedFee,
    required this.ttl,
  });
}
