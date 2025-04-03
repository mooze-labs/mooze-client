class FeeCalculator {
  final String assetId;
  final int fiatAmount; // Amount in cents

  const FeeCalculator({required this.assetId, required this.fiatAmount});

  double getFees() {
    final amountInReais = fiatAmount / 100.0;

    if (amountInReais >= 5000) return 2.75 / 100;
    if (amountInReais >= 500 && amountInReais < 5000) return 3.25 / 100;
    return 3.5 / 100;
  }
}
