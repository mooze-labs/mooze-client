class FeeCalculator {
  final String assetId;
  final int fiatAmount;

  const FeeCalculator({required this.assetId, required this.fiatAmount});

  double getFees() {
    if (fiatAmount >= 5000) return 2.75 / 100;
    if (fiatAmount >= 500 && fiatAmount < 5000) return 3.25 / 100;
    return 3.5 / 100;
  }
}
