
class FeeCalculator {
  final String assetId;
  final int fiatAmount; // Amount in cents
  final bool hasReferral;

  const FeeCalculator({
    required this.assetId,
    required this.fiatAmount,
    required this.hasReferral,
  });

  double getFees() {
    double amountInReais = fiatAmount / 100.0;
    if (assetId == "lbtc") {
      amountInReais =
          amountInReais / 1.02; // account for liquidity provider spread
    }
    double baseFee;

    if (amountInReais >= 5000) {
      baseFee = 2.75;
    } else if (amountInReais >= 500 && amountInReais < 5000) {
      baseFee = 3.25;
    } else {
      baseFee = 3.5;
    }

    // Apply referral discount if available
    if (hasReferral) {
      baseFee -= 0.5;
    }

    return baseFee / 100;
  }
}
