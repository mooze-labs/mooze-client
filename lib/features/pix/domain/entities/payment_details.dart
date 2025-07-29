class PaymentDetails {
  final double depositAmount;
  final double quote;
  final BigInt assetAmount;
  final double fee;

  PaymentDetails({
    required this.depositAmount,
    required this.quote,
    required this.assetAmount,
    required this.fee,
  });
}
