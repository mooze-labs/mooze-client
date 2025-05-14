class PegOperation {
  final String orderId;
  final bool pegIn;
  final String sideswapAddress;
  final String payoutAddress;
  final int amount;

  PegOperation({
    required this.orderId,
    required this.pegIn,
    required this.sideswapAddress,
    required this.payoutAddress,
    required this.amount,
  });
}
