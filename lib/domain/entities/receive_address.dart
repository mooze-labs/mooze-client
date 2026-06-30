import 'chain.dart';

/// A freshly-derived receive address (or invoice) for the user to share.
///
/// Lightning invoices are address-shaped from the consumer's POV — the same
/// QR-code container is reused — but [bolt11] is set instead of [address] for
/// `chain == ChainId.lightning`. On-chain chains set [address]. For Liquid
/// asset receive flows, [assetId] is set so the share-sheet can render
/// "send X USDt to this address".
class ReceiveAddress {
  const ReceiveAddress({
    required this.chain,
    this.address,
    this.bolt11,
    this.assetId,
    this.label,
    this.expiresAt,
    this.amountSat,
  });

  final ChainId chain;

  /// On-chain destination. Null for Lightning invoices.
  final String? address;

  /// BOLT-11 invoice. Null for on-chain receives.
  final String? bolt11;

  /// Optional asset ID for Liquid receives (when receiving a non-L-BTC asset).
  final String? assetId;

  /// Optional user-supplied label persisted alongside the next-derived address
  /// (BDK / LWK both expose a label channel; ignored for Lightning).
  final String? label;

  /// For Lightning invoices and time-bound on-chain swap addresses.
  final DateTime? expiresAt;

  /// For Lightning invoices that pre-commit to an amount.
  final int? amountSat;

  bool get isLightning => chain == ChainId.lightning;
  bool get isOnchain => !isLightning;
}
