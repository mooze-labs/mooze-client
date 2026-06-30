/// Domain types for the refund flow (Lightning swap recovery).
///
/// Field shapes intentionally mirror the underlying Breez SDK types
/// (`RefundableSwap`, `RecommendedFees`, `PrepareRefundResponse`,
/// `RefundResponse`) so widgets can rebind their imports without
/// changing field accesses. The translation between Breez SDK and these
/// types lives at the infra boundary (`LightningWalletServiceImpl`).
///
/// **Why V2 types instead of re-exporting Breez:** keeping `flutter_breez_liquid`
/// out of feature/UI imports lets us swap the underlying SDK without a
/// presentation-layer migration. Today's mirror is 1:1; tomorrow's
/// SDK-shape change stays contained in infra.
library;

/// A swap that can be refunded — typically a stuck or expired submarine
/// swap. The user can claim back the funds by broadcasting a refund tx
/// to the [refundAddress] of their choice.
class RefundableSwap {
  const RefundableSwap({
    required this.swapAddress,
    required this.amountSat,
    this.lastRefundTxId,
    this.timestamp,
  });

  /// On-chain address that holds the refundable funds. The refund tx
  /// spends from this.
  final String swapAddress;

  /// Amount available to refund, in satoshis.
  final int amountSat;

  /// Most recent refund attempt txid (if any). When set, a previous
  /// refund was broadcast but is still unconfirmed — the UI can offer
  /// fee-bumping / RBF instead of a fresh attempt.
  final String? lastRefundTxId;

  /// When the underlying swap was created (best-effort).
  final DateTime? timestamp;
}

/// Mempool-policy fee suggestions, used to populate refund fee pickers.
/// All values are sat/vB. Mirrors Breez `RecommendedFees` field-for-field.
class MempoolFees {
  const MempoolFees({
    required this.minimumFee,
    required this.economyFee,
    required this.hourFee,
    required this.halfHourFee,
    required this.fastestFee,
  });

  final int minimumFee;
  final int economyFee;
  final int hourFee;
  final int halfHourFee;
  final int fastestFee;
}

/// Caller-supplied parameters for preparing a refund tx. The infra layer
/// uses these to ask the SDK what the resulting tx would look like
/// (specifically its vbyte size, which the UI uses to render exact fee
/// figures). No state changes happen on prepare.
class PrepareRefundParams {
  const PrepareRefundParams({
    required this.swapAddress,
    required this.refundAddress,
    required this.feeRateSatPerVbyte,
  });

  final String swapAddress;
  final String refundAddress;
  final int feeRateSatPerVbyte;
}

/// Result of a successful prepare. Carries the vsize so the UI can
/// compute `feeRate * vsize` for an exact fee display.
class PrepareRefundOutcome {
  const PrepareRefundOutcome({
    required this.txVsize,
    this.feesSat,
    this.refundTxId,
  });

  final int txVsize;

  /// SDK-computed exact fee (sat) for this specific build, when
  /// available. Some SDK paths return only vsize; UI falls back to
  /// `feeRate * vsize` in that case.
  final int? feesSat;

  /// If the SDK already prepared and signed a tx, its txid. Most paths
  /// require an explicit `executeRefund` call to broadcast.
  final String? refundTxId;
}

/// Caller-supplied parameters for broadcasting a refund tx.
class ExecuteRefundParams {
  const ExecuteRefundParams({
    required this.swapAddress,
    required this.refundAddress,
    required this.feeRateSatPerVbyte,
  });

  final String swapAddress;
  final String refundAddress;
  final int feeRateSatPerVbyte;
}

/// Result of a successful refund broadcast. The [refundTxId] uniquely
/// identifies the refund on-chain — the UI displays it as the
/// confirmation receipt.
class RefundOutcome {
  const RefundOutcome({required this.refundTxId});
  final String refundTxId;
}
