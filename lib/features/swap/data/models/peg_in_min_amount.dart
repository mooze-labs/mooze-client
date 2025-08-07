/// Minimum peg-in amount
class PegInMinAmount {
  final int minAmount;

  PegInMinAmount({required this.minAmount});

  factory PegInMinAmount.fromJson(Map<String, dynamic> json) {
    return PegInMinAmount(minAmount: json['min_amount']);
  }
}
