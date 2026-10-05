/// Low balance result for a quote attempt
class QuoteLowBalance {
  final int available;
  final int baseAmount;
  final int quoteAmount;
  final int serverFee;
  final int fixedFee;

  QuoteLowBalance({
    required this.available,
    required this.baseAmount,
    required this.quoteAmount,
    required this.serverFee,
    required this.fixedFee,
  });
}
