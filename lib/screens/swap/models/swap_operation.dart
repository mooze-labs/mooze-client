class SwapOperation {
  final String sendAsset;
  final String receiveAsset;
  final BigInt sendAmount;
  final BigInt receiveAmount;

  SwapOperation({
    required this.sendAsset,
    required this.receiveAsset,
    required this.sendAmount,
    required this.receiveAmount,
  });
}
