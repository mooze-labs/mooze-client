import 'dart:async';

import '../entities/peg.dart';

/// A peg the tracker is watching, as the UI sees it.
class TrackedPeg {
  const TrackedPeg({
    required this.orderId,
    required this.direction,
    required this.phase,
    required this.amountSat,
    required this.depositAddress,
    this.fundingTxId,
    this.payoutTxId,
    this.confirmations,
    this.requiredConfirmations,
    this.errorMessage,
  });

  final String orderId;
  final PegDirection direction;
  final PegPhase phase;
  final BigInt amountSat;
  final String depositAddress;
  final String? fundingTxId;
  final String? payoutTxId;
  final int? confirmations;
  final int? requiredConfirmations;
  final String? errorMessage;

  bool get isTerminal => phase.isTerminal;

  TrackedPeg copyWith({
    PegPhase? phase,
    String? payoutTxId,
    int? confirmations,
    int? requiredConfirmations,
    String? errorMessage,
  }) => TrackedPeg(
    orderId: orderId,
    direction: direction,
    phase: phase ?? this.phase,
    amountSat: amountSat,
    depositAddress: depositAddress,
    fundingTxId: fundingTxId,
    payoutTxId: payoutTxId ?? this.payoutTxId,
    confirmations: confirmations ?? this.confirmations,
    requiredConfirmations: requiredConfirmations ?? this.requiredConfirmations,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}

/// Follows in-flight pegs until they reach a terminal phase.
abstract class PegTracker {
  /// Live view of everything being tracked.
  Stream<List<TrackedPeg>> get pegs;

  /// The last known tracked pegs.
  List<TrackedPeg> get current;

  /// Resumes the stored pending pegs of the active wallet. Idempotent.
  Future<void> restore();

  /// Begins polling a freshly funded peg.
  void track(TrackedPeg peg);

  /// Stops polling [orderId] without changing the stored state.
  void untrack(String orderId);

  void dispose();
}
