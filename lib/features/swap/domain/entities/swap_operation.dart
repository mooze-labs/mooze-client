class SwapOperation {
  final int id;
  final String sendAsset;
  final String receiveAsset;
  final BigInt sendAmount;
  final BigInt receiveAmount;
  final int ttl;

  SwapOperation({
    required this.id,
    required this.sendAsset,
    required this.receiveAsset,
    required this.sendAmount,
    required this.receiveAmount,
    required this.ttl,
  });
}
