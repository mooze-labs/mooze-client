class PaymentDetails {
  final double depositAmount;
  final double quote;
  final BigInt assetAmount;
  final double fee;
  final String address;

  PaymentDetails({
    required this.depositAmount,
    required this.quote,
    required this.assetAmount,
    required this.fee,
    required this.address,
  });
}
