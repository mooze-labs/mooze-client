/// Detailed fee model for on-chain BTC sending via Breez
///
/// According to Breez SDK Liquid documentation:
/// - L-BTC Lockup Transaction Fee: ~34 sats (0.1 sat/vbyte)
/// - BTC Lockup Transaction Fee: mining fees based on mempool
/// - Swap Service Fee: 0.1% of the amount sent
/// - BTC Claim Transaction Fee: fees to claim the BTC funds
class BreezOnchainFeeBreakdown {
  /// L-BTC lockup transaction fee (~34 sats fixed)
  final BigInt liquidLockupFeeSat;

  /// BTC lockup transaction fee (variable, mempool-based)
  final BigInt bitcoinLockupFeeSat;

  /// Swap service fee (0.1% of the amount)
  final BigInt swapServiceFeeSat;

  /// BTC claim transaction fee (variable, mempool-based)
  final BigInt claimFeeSat;

  /// Total fee (sum of all components)
  final BigInt totalFeesSat;

  const BreezOnchainFeeBreakdown({
    required this.liquidLockupFeeSat,
    required this.bitcoinLockupFeeSat,
    required this.swapServiceFeeSat,
    required this.claimFeeSat,
    required this.totalFeesSat,
  });

  /// Creates a breakdown from the Breez totalFeesSat
  /// Estimates the components based on the returned total value
  factory BreezOnchainFeeBreakdown.fromTotal({
    required BigInt totalFeesSat,
    required BigInt amountSat,
  }) {
    // L-BTC lockup fee is fixed
    final liquidLockupFee = BigInt.from(34);

    // Service fee is 0.1% of the amount
    final serviceFee = (amountSat * BigInt.from(10)) ~/ BigInt.from(10000);

    // The remaining amount is split between BTC lockup and claim (approx.)
    final remainingFees = totalFeesSat - liquidLockupFee - serviceFee;
    final btcLockupFee = remainingFees ~/ BigInt.from(2);
    final claimFee = remainingFees - btcLockupFee;

    return BreezOnchainFeeBreakdown(
      liquidLockupFeeSat: liquidLockupFee,
      bitcoinLockupFeeSat: btcLockupFee,
      swapServiceFeeSat: serviceFee,
      claimFeeSat: claimFee,
      totalFeesSat: totalFeesSat,
    );
  }

  double get liquidLockupFeeBtc => liquidLockupFeeSat.toDouble() / 100000000;
  double get bitcoinLockupFeeBtc => bitcoinLockupFeeSat.toDouble() / 100000000;
  double get swapServiceFeeBtc => swapServiceFeeSat.toDouble() / 100000000;
  double get claimFeeBtc => claimFeeSat.toDouble() / 100000000;
  double get totalFeesBtc => totalFeesSat.toDouble() / 100000000;
}
