class LiquidSendDraft {
  const LiquidSendDraft({
    required this.pset,
    required this.destination,
    required this.amountSat,
    required this.feeSat,
    required this.feeRateSatPerKvb,
    required this.drain,
  });

  /// Transaction PSET.
  final String pset;

  /// Recipient Liquid address.
  final String destination;

  /// Amount sent to the recipient, in satoshis.
  final BigInt amountSat;

  /// Network fee, in satoshis.
  final BigInt feeSat;

  /// Fee rate used to build the transaction, in sat/kvB.
  final double feeRateSatPerKvb;

  /// Whether the transaction spends the entire wallet balance.
  final bool drain;

  /// Total amount debited from the wallet.
  BigInt get totalSat => amountSat + feeSat;
}