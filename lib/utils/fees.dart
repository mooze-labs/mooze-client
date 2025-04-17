import 'package:shared_preferences/shared_preferences.dart';

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
    final amountInReais = fiatAmount / 100.0;
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
