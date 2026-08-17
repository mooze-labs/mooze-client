import 'dart:async';

import '../entities/peg.dart';
import '../entities/peg_error.dart';
import '../repositories/peg_repository.dart';
import 'peg_orchestrator.dart';

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

/// Source of pegs to resume after a restart.
abstract class PegRecoverySource {
  /// Non-terminal pegs for the active wallet, oldest first.
  Future<List<TrackedPeg>> loadActivePegs();
}

class PegTracker {
  PegTracker({
    required PegRepository repository,
    required PegStore store,
    required PegRecoverySource recoverySource,
    Duration Function(PegPhase)? intervalOverride,
  }) : _repository = repository,
       _store = store,
       _recovery = recoverySource,
       _intervalOverride = intervalOverride;

  final PegRepository _repository;
  final PegStore _store;
  final PegRecoverySource _recovery;
  final Duration Function(PegPhase)? _intervalOverride;

  final Map<String, TrackedPeg> _tracked = {};
  final Map<String, Timer> _timers = {};
  final StreamController<List<TrackedPeg>> _controller =
      StreamController<List<TrackedPeg>>.broadcast();

  bool _disposed = false;
  bool _offline = false;

  /// Live view of everything being tracked.
  Stream<List<TrackedPeg>> get pegs => _controller.stream;

  List<TrackedPeg> get current => List.unmodifiable(_tracked.values);

  static Duration pollIntervalFor(PegPhase phase) => switch (phase) {
    PegPhase.awaitingDeposit => const Duration(minutes: 5),
    PegPhase.detected => const Duration(seconds: 30),
    PegPhase.processing => const Duration(seconds: 30),
    _ => Duration.zero,
  };

  Duration _interval(PegPhase phase) =>
      _intervalOverride?.call(phase) ?? pollIntervalFor(phase);

  /// Load persisted non-terminal pegs and resume polling. Idempotent.
  Future<void> restore() async {
    if (_disposed) return;
    final restored = await _recovery.loadActivePegs();
    for (final peg in restored) {
      if (_tracked.containsKey(peg.orderId)) continue;
      _tracked[peg.orderId] = peg;
      _schedule(peg.orderId);
    }
    _emit();
  }

  /// Begin tracking a freshly created peg.
  void track(TrackedPeg peg) {
    if (_disposed) return;
    _tracked[peg.orderId] = peg;
    _emit();
    // Poll once immediately: a peg-out deposit is already on the wire by the
    // time we get here, so the first status is usually informative.
    unawaited(refresh(peg.orderId));
  }

  /// Stop polling without changing the stored state. Used when the tracker is
  /// torn down, not when a peg finishes.
  void untrack(String orderId) {
    _timers.remove(orderId)?.cancel();
    _tracked.remove(orderId);
    _emit();
  }

  /// Pause polling — connectivity is gone. Timers are cancelled rather than
  /// left to fire into a dead socket.
  void goOffline() {
    if (_offline) return;
    _offline = true;
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  /// Resume polling after connectivity returns, refreshing everything once.
  void goOnline() {
    if (!_offline) return;
    _offline = false;
    for (final orderId in _tracked.keys.toList()) {
      unawaited(refresh(orderId));
    }
  }

  /// Poll [orderId] once and persist any change.
  Future<void> refresh(String orderId) async {
    if (_disposed || _offline) return;
    final peg = _tracked[orderId];
    if (peg == null || peg.isTerminal) return;

    final result =
        await _repository
            .getStatus(direction: peg.direction, orderId: orderId)
            .run();

    if (_disposed) return;

    await result.match(
      (error) async {
        // A transport hiccup must never look like a state change. The only
        // error that ends tracking is the order genuinely not existing.
        if (error is PegOrderNotFound) {
          await _finalise(
            peg.copyWith(phase: PegPhase.failed, errorMessage: error.message),
          );
          return;
        }
        _schedule(orderId);
      },
      (progress) async {
        final updated = _merge(peg, progress);
        if (!updated.phase.isTerminal &&
            updated.phase.progressRank < peg.phase.progressRank) {
          _schedule(orderId);
          return;
        }

        _tracked[orderId] = updated;
        _emit();

        if (updated.isTerminal) {
          await _finalise(updated);
        } else {
          _schedule(orderId);
        }
      },
    );
  }

  TrackedPeg _merge(TrackedPeg peg, PegProgress progress) {
    final deposit = progress.deposits.isEmpty ? null : progress.deposits.first;
    return peg.copyWith(
      phase: progress.phase,
      payoutTxId: progress.payoutTxId,
      confirmations: deposit?.detectedConfirmations,
      requiredConfirmations: deposit?.totalConfirmations,
    );
  }

  Future<void> _finalise(TrackedPeg peg) async {
    _timers.remove(peg.orderId)?.cancel();
    _tracked[peg.orderId] = peg;
    _emit();
    try {
      await _store.recordTerminal(
        peg.orderId,
        phase: peg.phase,
        payoutTxId: peg.payoutTxId,
        errorMessage: peg.errorMessage,
      );
    } catch (_) {
      // Best-effort. The next restore() will re-poll and try again; a write
      // failure must not crash the tracker.
    }
  }

  void _schedule(String orderId) {
    if (_disposed || _offline) return;
    final peg = _tracked[orderId];
    if (peg == null || peg.isTerminal) return;

    _timers.remove(orderId)?.cancel();
    final delay = _interval(peg.phase);
    if (delay == Duration.zero) return;
    _timers[orderId] = Timer(delay, () => unawaited(refresh(orderId)));
  }

  void _emit() {
    if (_disposed || _controller.isClosed) return;
    _controller.add(current);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _controller.close();
  }
}
