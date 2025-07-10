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

  factory QuoteLowBalance.fromJson(Map<String, dynamic> json) {
    final lowBalance = json['status']['LowBalance'];
    return QuoteLowBalance(
      available: lowBalance['available'],
      baseAmount: lowBalance['base_amount'],
      quoteAmount: lowBalance['quote_amount'],
      serverFee: lowBalance['server_fee'],
      fixedFee: lowBalance['fixed_fee'],
    );
  }
}
