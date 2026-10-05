library;

const String pegEvidenceStatusPending = 'pending';
const String pegEvidenceStatusCompleted = 'completed';
const String pegEvidenceStatusFailed = 'failed';
const String pegEvidenceStatusInsufficientAmount = 'insufficient_amount';

enum PegLeg { funding, payout }

class PegRecord {
  const PegRecord({
    required this.orderId,
    required this.isPegIn,
    required this.amountSat,
    required this.createdAt,
    required this.status,
    this.depositAddress,
    this.payoutAddress,
    this.fundingTxId,
    this.payoutTxId,
  });

  /// SideSwap order id — the stable handle for this peg.
  final String orderId;

  /// `true` for BTC → L-BTC. Mirrors the `pegIn` column.
  final bool isPegIn;

  final BigInt amountSat;
  final DateTime createdAt;

  /// Raw `Pegs.status` value. Kept as a string for the same reason the column
  /// is: a new provider state must not need a schema migration.
  final String status;

  /// SideSwap's deposit address — the destination of the funding transaction.
  final String? depositAddress;

  /// Our address that receives the proceeds.
  final String? payoutAddress;

  /// Txid the wallet broadcast to fund the peg.
  final String? fundingTxId;

  /// Txid SideSwap paid out on the destination chain.
  final String? payoutTxId;

  /// Terminal without a payout. SideSwap holds the funds on
  /// `insufficient_amount`; `failed` means the peg never executed. Either way
  /// the funding leg has **no** counterpart, so any pair the heuristics build
  /// around it is a false positive.
  bool get isUnpaid =>
      status == pegEvidenceStatusFailed ||
      status == pegEvidenceStatusInsufficientAmount;

  /// Both legs known — this record can join a pair on its own, with no
  /// heuristic involvement at all.
  bool get hasBothLegs => fundingTxId != null && payoutTxId != null;

  /// Which leg [txId] is, or `null` if this record does not mention it.
  PegLeg? legFor(String txId) {
    if (fundingTxId == txId) return PegLeg.funding;
    if (payoutTxId == txId) return PegLeg.payout;
    return null;
  }
}

enum PegEvidenceVerdict {
  /// Local records prove this pair belongs to one peg order.
  confirmed,

  /// Local records prove this pair is wrong. The join must not group it.
  rejected,

  /// No record mentions either transaction. Existing heuristics decide.
  abstain,
}

/// A verdict plus why, so a rejection is explainable in a log instead of
/// silently changing what the user sees.
class PegEvidenceCheck {
  const PegEvidenceCheck._(this.verdict, this.reason, this.record);

  const PegEvidenceCheck.abstain([this.reason = 'no local record'])
    : verdict = PegEvidenceVerdict.abstain,
      record = null;

  factory PegEvidenceCheck.confirmed(PegRecord record, String reason) =>
      PegEvidenceCheck._(PegEvidenceVerdict.confirmed, reason, record);

  factory PegEvidenceCheck.rejected(PegRecord record, String reason) =>
      PegEvidenceCheck._(PegEvidenceVerdict.rejected, reason, record);

  final PegEvidenceVerdict verdict;
  final String reason;

  /// The record that produced a confirm or reject. `null` when abstaining.
  final PegRecord? record;

  bool get isConfirmed => verdict == PegEvidenceVerdict.confirmed;
  bool get isRejected => verdict == PegEvidenceVerdict.rejected;
  bool get isAbstain => verdict == PegEvidenceVerdict.abstain;

  @override
  String toString() => '${verdict.name}($reason)';
}

/// An immutable, indexed snapshot of the local peg records.
///
/// Built once per join pass and read many times, so lookups are O(1).
class PegEvidence {
  PegEvidence(List<PegRecord> records)
    : records = List.unmodifiable(records) {
    for (final r in records) {
      final funding = r.fundingTxId;
      final payout = r.payoutTxId;
      if (funding != null) _byTxId[funding] = r;
      if (payout != null) _byTxId[payout] = r;
      final deposit = r.depositAddress;
      if (deposit != null && deposit.isNotEmpty) _byDepositAddress[deposit] = r;
    }
  }

  /// The no-evidence case: every check abstains, so the join behaves exactly as
  /// it did before this layer existed.
  factory PegEvidence.empty() => PegEvidence(const []);

  final List<PegRecord> records;

  final Map<String, PegRecord> _byTxId = {};
  final Map<String, PegRecord> _byDepositAddress = {};

  bool get isEmpty => records.isEmpty;
  bool get isNotEmpty => records.isNotEmpty;

  /// Record that claims [txId] as either of its legs.
  PegRecord? recordForTxId(String txId) => _byTxId[txId];

  /// Record whose SideSwap deposit address is [address].
  ///
  /// The fallback when `recordFunded` never landed — a funding tx that was
  /// broadcast but not recorded is still identifiable by where it paid.
  PegRecord? recordForDepositAddress(String? address) =>
      address == null ? null : _byDepositAddress[address];

  /// Records that can join a pair by themselves. Excludes terminal-unpaid
  /// orders, which have no genuine counterpart to join to.
  Iterable<PegRecord> get joinableRecords =>
      records.where((r) => r.hasBothLegs && !r.isUnpaid);

  PegEvidenceCheck validatePair({
    required String sendTxId,
    required String receiveTxId,
    required bool isPegIn,
    String? sendDestination,
  }) {
    if (isEmpty) return const PegEvidenceCheck.abstain('no local peg records');

    final sendRecord = recordForTxId(sendTxId);
    final receiveRecord = recordForTxId(receiveTxId);

    // ── Both legs named by records ──────────────────────────────────────
    if (sendRecord != null && receiveRecord != null) {
      if (sendRecord.orderId != receiveRecord.orderId) {
        // Each leg belongs to a *different* peg. Pairing them mixes two
        // orders — the exact false positive two pegs in quick succession
        // produce under an amount+time window.
        return PegEvidenceCheck.rejected(
          sendRecord,
          'legs belong to different orders '
          '(${sendRecord.orderId} vs ${receiveRecord.orderId})',
        );
      }
      return _checkRoles(sendRecord, sendTxId, receiveTxId, isPegIn);
    }

    // ── Exactly one leg named ───────────────────────────────────────────
    if (sendRecord != null || receiveRecord != null) {
      final onSend = sendRecord != null;
      return validateLeg(
        txId: onSend ? sendTxId : receiveTxId,
        isPegIn: isPegIn,
        role: onSend ? PegLeg.funding : PegLeg.payout,
      );
    }

    // ── Neither leg named: try the deposit address ───────────────────────
    final byAddress = recordForDepositAddress(sendDestination);
    if (byAddress != null) {
      if (byAddress.isUnpaid) {
        return PegEvidenceCheck.rejected(
          byAddress,
          'order ${byAddress.orderId} is ${byAddress.status} — funding leg has '
          'no counterpart',
        );
      }
      if (byAddress.isPegIn != isPegIn) {
        return PegEvidenceCheck.rejected(
          byAddress,
          'order ${byAddress.orderId} direction disagrees with the join',
        );
      }
      return PegEvidenceCheck.confirmed(
        byAddress,
        'send leg pays the deposit address of ${byAddress.orderId}',
      );
    }

    // Records exist, but none of them mentions this pair. It may be a Breez
    // chain swap, a pre-restore peg, or a genuine non-peg. We cannot tell, so
    // we do not interfere.
    return const PegEvidenceCheck.abstain(
      'no record mentions either leg',
    );
  }

  PegEvidenceCheck validateLeg({
    required String txId,
    required bool isPegIn,
    required PegLeg role,
    String? destination,
  }) {
    if (isEmpty) return const PegEvidenceCheck.abstain('no local peg records');

    final record =
        recordForTxId(txId) ??
        (role == PegLeg.funding ? recordForDepositAddress(destination) : null);
    if (record == null) {
      return const PegEvidenceCheck.abstain('no record mentions this leg');
    }

    if (record.isUnpaid) {
      // Terminal without a payout: there is no second leg, so a swap row built
      // around this transaction would claim an exchange that never happened.
      return PegEvidenceCheck.rejected(
        record,
        'order ${record.orderId} is ${record.status} — no payout exists',
      );
    }

    if (record.isPegIn != isPegIn) {
      return PegEvidenceCheck.rejected(
        record,
        'order ${record.orderId} is a ${record.isPegIn ? "peg-in" : "peg-out"}, '
        'join inferred ${isPegIn ? "peg-in" : "peg-out"}',
      );
    }

    final leg = record.legFor(txId);
    if (leg != null && leg != role) {
      return PegEvidenceCheck.rejected(
        record,
        'tx $txId is the ${leg.name} leg of ${record.orderId} but was used as '
        'the ${role.name} leg',
      );
    }

    return PegEvidenceCheck.confirmed(
      record,
      'order ${record.orderId} claims the ${role.name} leg',
    );
  }

  /// Both legs map to one record — check direction and roles line up.
  PegEvidenceCheck _checkRoles(
    PegRecord record,
    String sendTxId,
    String receiveTxId,
    bool isPegIn,
  ) {
    if (record.isPegIn != isPegIn) {
      return PegEvidenceCheck.rejected(
        record,
        'order ${record.orderId} is a ${record.isPegIn ? "peg-in" : "peg-out"}, '
        'join inferred ${isPegIn ? "peg-in" : "peg-out"}',
      );
    }
    if (record.legFor(sendTxId) != PegLeg.funding ||
        record.legFor(receiveTxId) != PegLeg.payout) {
      return PegEvidenceCheck.rejected(
        record,
        'legs of ${record.orderId} are swapped: send=$sendTxId '
        'receive=$receiveTxId',
      );
    }
    return PegEvidenceCheck.confirmed(
      record,
      'both legs match order ${record.orderId}',
    );
  }
}
