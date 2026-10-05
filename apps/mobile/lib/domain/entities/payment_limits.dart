import 'chain.dart';

/// Min/max amounts the underlying SDK accepts for the given chain. Used by
/// the send-flow validation step before the user can press "Review".
///
/// Chain-specific behaviour lives in the repository implementation (Lightning
/// limits derive from the LSP's offer; Liquid/Bitcoin from network dust + fee
/// floor). Callers see one normalised shape regardless of chain.
class PaymentLimits {
  const PaymentLimits({
    required this.chain,
    required this.sendMinSat,
    required this.sendMaxSat,
    this.receiveMinSat,
    this.receiveMaxSat,
  });

  final ChainId chain;

  /// Smallest payment amount the SDK will accept on send.
  final int sendMinSat;

  /// Largest payment amount the SDK will accept on send. For Lightning this
  /// reflects the LSP's current capacity; for on-chain it is `BigInt.from(2^53-1)`
  /// effectively (no upper bound beyond available balance).
  final int sendMaxSat;

  /// Smallest payment amount the SDK will accept on receive. Null when not
  /// applicable (on-chain has no per-tx receive minimum).
  final int? receiveMinSat;

  /// Largest payment amount the SDK will accept on receive. Used by the
  /// receive flow to gate amount entry. Null when not applicable.
  final int? receiveMaxSat;
}
