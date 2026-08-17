enum PegDirection {
  /// BTC → L-BTC. Funded from the BDK Bitcoin wallet.
  pegIn,

  /// L-BTC → BTC. Funded from the LWK Liquid wallet.
  pegOut;

  bool get isPegIn => this == PegDirection.pegIn;

  /// Wire representation — SideSwap's `peg_in` boolean.
  bool get asPegInFlag => isPegIn;

  /// Audit-log label, matching `SwapAuditRepository.recordPending`.
  String get auditDirection => isPegIn ? 'btc_to_lbtc' : 'lbtc_to_btc';
}

/// A peg order created with SideSwap, before any deposit has been made.
class PegOrder {
  const PegOrder({
    required this.orderId,
    required this.direction,
    required this.depositAddress,
    required this.payoutAddress,
    required this.createdAt,
    this.expiresAt,
  });

  /// SideSwap's order identifier. The only handle for querying status, and
  /// the recovery key if the app dies mid-flow.
  final String orderId;

  final PegDirection direction;

  /// Where the user must send funds. Bitcoin address for a peg-in, Liquid
  /// address for a peg-out. Supplied by SideSwap.
  final String depositAddress;

  /// Where the proceeds land. Liquid address for a peg-in, Bitcoin address
  /// for a peg-out. Supplied by us.
  final String payoutAddress;

  final DateTime createdAt;

  /// `null` when SideSwap reports no expiry (wire value `0`).
  final DateTime? expiresAt;

  bool get isExpired {
    final e = expiresAt;
    return e != null && DateTime.now().isAfter(e);
  }
}

enum PegPhase {
  /// Order exists; no deposit seen yet.
  awaitingDeposit,

  /// Deposit seen on-chain, accumulating confirmations.
  detected,

  /// Confirmed; SideSwap is executing the federation peg.
  processing,

  /// Proceeds sent. Terminal.
  completed,

  insufficientAmount,

  /// Local failure (broadcast failed, order rejected). Terminal.
  failed;

  bool get isTerminal =>
      this == PegPhase.completed ||
      this == PegPhase.insufficientAmount ||
      this == PegPhase.failed;

  int get progressRank => switch (this) {
    PegPhase.failed => 0,
    PegPhase.insufficientAmount => 1,
    PegPhase.awaitingDeposit => 2,
    PegPhase.detected => 3,
    PegPhase.processing => 4,
    PegPhase.completed => 5,
  };
}

/// One deposit transaction inside a peg order.
class PegDeposit {
  const PegDeposit({
    required this.txId,
    required this.phase,
    required this.amountSat,
    this.payoutSat,
    this.payoutTxId,
    this.detectedConfirmations,
    this.totalConfirmations,
  });

  final String txId;
  final PegPhase phase;
  final int amountSat;

  /// Amount actually paid out, net of SideSwap's fee. Null until known.
  final int? payoutSat;

  /// Transaction id on the *destination* chain. Null until paid out.
  final String? payoutTxId;

  final int? detectedConfirmations;
  final int? totalConfirmations;
}

/// Aggregated state of a peg order.
class PegProgress {
  const PegProgress({
    required this.orderId,
    required this.direction,
    required this.phase,
    required this.deposits,
    required this.depositAddress,
    required this.payoutAddress,
  });

  final String orderId;
  final PegDirection direction;

  /// Order-level phase, derived from [deposits] by least-advanced-wins.
  final PegPhase phase;

  final List<PegDeposit> deposits;
  final String depositAddress;
  final String payoutAddress;

  bool get isTerminal => phase.isTerminal;

  /// Total deposited across every funding transaction.
  int get totalDepositedSat => deposits.fold(0, (sum, d) => sum + d.amountSat);

  /// Total paid out, where known.
  int get totalPayoutSat =>
      deposits.fold(0, (sum, d) => sum + (d.payoutSat ?? 0));

  /// Destination-chain txid, once there is exactly one payout to point at.
  String? get payoutTxId {
    final ids = deposits
        .map((d) => d.payoutTxId)
        .whereType<String>()
        .toList(growable: false);
    return ids.length == 1 ? ids.single : null;
  }
}

class PegServerLimits {
  const PegServerLimits({
    required this.minPegInSat,
    required this.minPegOutSat,
    required this.serverFeePercentPegIn,
    required this.serverFeePercentPegOut,
  });

  final int minPegInSat;
  final int minPegOutSat;
  final double serverFeePercentPegIn;
  final double serverFeePercentPegOut;

  int minimumFor(PegDirection direction) =>
      direction.isPegIn ? minPegInSat : minPegOutSat;

  double feePercentFor(PegDirection direction) =>
      direction.isPegIn ? serverFeePercentPegIn : serverFeePercentPegOut;

  /// SideSwap's cut for [amountSat], rounded up so the displayed fee never
  /// understates what the user pays.
  int serviceFeeSat(PegDirection direction, int amountSat) {
    final pct = feePercentFor(direction);
    if (pct <= 0 || amountSat <= 0) return 0;
    return (amountSat * pct / 100).ceil();
  }
}
