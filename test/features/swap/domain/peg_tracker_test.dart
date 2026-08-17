import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/features/swap/domain/entities/peg.dart';
import 'package:mooze_mobile/features/swap/domain/entities/peg_error.dart';
import 'package:mooze_mobile/features/swap/domain/repositories/peg_repository.dart';
import 'package:mooze_mobile/features/swap/domain/usecases/peg_orchestrator.dart';
import 'package:mooze_mobile/features/swap/domain/usecases/peg_tracker.dart';

void main() {
  late _FakeRepo repo;
  late _RecordingStore store;
  late _FakeRecovery recovery;
  late PegTracker tracker;

  TrackedPeg pending(String id, {PegPhase phase = PegPhase.awaitingDeposit}) =>
      TrackedPeg(
        orderId: id,
        direction: PegDirection.pegOut,
        phase: phase,
        amountSat: BigInt.from(100000),
        depositAddress: 'lq1-deposit',
        fundingTxId: 'lwk-txid',
      );

  setUp(() {
    repo = _FakeRepo();
    store = _RecordingStore();
    recovery = _FakeRecovery();
    tracker = PegTracker(
      repository: repo,
      store: store,
      recoverySource: recovery,
      // Near-zero cadence so scheduling is observable without real waits.
      intervalOverride:
          (phase) =>
              phase.isTerminal
                  ? Duration.zero
                  : const Duration(milliseconds: 5),
    );
  });

  tearDown(() => tracker.dispose());

  group('restart recovery', () {
    test('restores persisted non-terminal pegs and starts polling', () async {
      recovery.pegs = [pending('order-1'), pending('order-2')];

      await tracker.restore();

      expect(tracker.current.map((p) => p.orderId), ['order-1', 'order-2']);
    });

    test('restore is idempotent — a second call does not duplicate', () async {
      recovery.pegs = [pending('order-1')];

      await tracker.restore();
      await tracker.restore();

      expect(tracker.current, hasLength(1));
    });
  });

  group('status transitions', () {
    test('advances through detected → processing → completed', () async {
      tracker.track(pending('order-1'));

      repo.progress = _progress('order-1', PegPhase.detected);
      await tracker.refresh('order-1');
      expect(tracker.current.single.phase, PegPhase.detected);

      repo.progress = _progress('order-1', PegPhase.processing);
      await tracker.refresh('order-1');
      expect(tracker.current.single.phase, PegPhase.processing);

      repo.progress = _progress(
        'order-1',
        PegPhase.completed,
        payoutTxId: 'btc-payout',
      );
      await tracker.refresh('order-1');
      expect(tracker.current.single.phase, PegPhase.completed);
      expect(tracker.current.single.payoutTxId, 'btc-payout');
    });

    test('persists the terminal state exactly once', () async {
      tracker.track(pending('order-1'));
      await pumpEventQueue();
      repo.progress = _progress('order-1', PegPhase.completed);

      await tracker.refresh('order-1');
      await tracker.refresh('order-1'); // already terminal — must be a no-op

      expect(store.terminals, ['order-1:completed']);
    });

    test('never walks a peg backwards', () async {
      // Out-of-order responses would otherwise re-open a nearly-finished
      // operation in the UI.
      tracker.track(pending('order-1'));
      await pumpEventQueue();
      repo.progress = _progress('order-1', PegPhase.processing);
      await tracker.refresh('order-1');

      repo.progress = _progress('order-1', PegPhase.detected);
      await tracker.refresh('order-1');

      expect(tracker.current.single.phase, PegPhase.processing);
    });

    test('maps insufficientAmount to a terminal state, not a refund', () async {
      // SideSwap holds under-funded deposits; there is no Boltz-style refund
      // path, so surfacing this as `refundable` would offer a dead action.
      tracker.track(pending('order-1'));
      await pumpEventQueue();
      repo.progress = _progress('order-1', PegPhase.insufficientAmount);

      await tracker.refresh('order-1');

      expect(tracker.current.single.phase, PegPhase.insufficientAmount);
      expect(store.terminals, ['order-1:insufficientAmount']);
    });

    test('surfaces confirmation counts', () async {
      tracker.track(pending('order-1'));
      await pumpEventQueue();
      repo.progress = _progress(
        'order-1',
        PegPhase.detected,
        detected: 1,
        total: 2,
      );

      await tracker.refresh('order-1');

      expect(tracker.current.single.confirmations, 1);
      expect(tracker.current.single.requiredConfirmations, 2);
    });
  });

  group('error handling', () {
    test('a transport failure leaves the phase untouched', () async {
      // A dropped socket is not a state change; treating it as one would
      // show the user a failure that never happened.
      repo.error = const PegTransportFailure('socket closed');
      tracker.track(pending('order-1', phase: PegPhase.processing));
      await pumpEventQueue();

      await tracker.refresh('order-1');

      expect(tracker.current.single.phase, PegPhase.processing);
      expect(store.terminals, isEmpty);
    });

    test('an unknown order is terminal', () async {
      repo.error = const PegOrderNotFound('order-1');
      tracker.track(pending('order-1'));
      await pumpEventQueue();

      expect(tracker.current.single.phase, PegPhase.failed);
      expect(store.terminals, ['order-1:failed']);
    });

    test('a store write failure does not crash the tracker', () async {
      tracker.track(pending('order-1'));
      await pumpEventQueue();
      store.failTerminal = true;
      repo.progress = _progress('order-1', PegPhase.completed);

      await tracker.refresh('order-1');

      expect(tracker.current.single.phase, PegPhase.completed);
    });
  });

  group('connectivity', () {
    test('offline pauses polling; online refreshes everything', () async {
      tracker.track(pending('order-1'));
      await pumpEventQueue();
      tracker.goOffline();

      final before = repo.statusCalls;
      repo.progress = _progress('order-1', PegPhase.detected);
      await tracker.refresh('order-1');
      expect(repo.statusCalls, before, reason: 'offline must not poll');

      tracker.goOnline();
      await pumpEventQueue();
      expect(repo.statusCalls, greaterThan(before));
    });
  });

  group('lifecycle', () {
    test('emits on every change', () async {
      final seen = <int>[];
      final sub = tracker.pegs.listen((list) => seen.add(list.length));

      tracker.track(pending('order-1'));
      tracker.track(pending('order-2'));
      await pumpEventQueue();

      expect(seen, isNotEmpty);
      expect(seen.last, 2);
      await sub.cancel();
    });

    test('dispose cancels timers and stops polling', () async {
      tracker.track(pending('order-1'));
      await pumpEventQueue();
      final calls = repo.statusCalls;

      tracker.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(repo.statusCalls, calls);
    });

    test('refresh after dispose is a no-op', () async {
      tracker.track(pending('order-1'));
      tracker.dispose();
      await tracker.refresh('order-1');
      // No throw, no emission on a closed controller.
    });
  });
}

PegProgress _progress(
  String orderId,
  PegPhase phase, {
  String? payoutTxId,
  int? detected,
  int? total,
}) => PegProgress(
  orderId: orderId,
  direction: PegDirection.pegOut,
  phase: phase,
  depositAddress: 'lq1-deposit',
  payoutAddress: 'bc1-payout',
  deposits: [
    PegDeposit(
      txId: 'lwk-txid',
      phase: phase,
      amountSat: 100000,
      payoutTxId: payoutTxId,
      detectedConfirmations: detected,
      totalConfirmations: total,
    ),
  ],
);

class _FakeRepo implements PegRepository {
  /// Defaults to a live, non-terminal order. `track()` fires an eager poll
  /// (a peg-out deposit is already on the wire by then), so a fake that
  /// answered "not found" until each test configured it would make every
  /// peg terminal before the test body ran.
  PegProgress? progress = _progress('order-1', PegPhase.awaitingDeposit);
  PegError? error;
  int statusCalls = 0;

  @override
  TaskEither<PegError, PegServerLimits> getLimits() => TaskEither.right(
    const PegServerLimits(
      minPegInSat: 1000,
      minPegOutSat: 1000,
      serverFeePercentPegIn: 0.1,
      serverFeePercentPegOut: 0.1,
    ),
  );

  @override
  TaskEither<PegError, PegOrder> createOrder({
    required PegDirection direction,
    required String payoutAddress,
  }) => TaskEither.left(const PegProviderRejected('not used'));

  @override
  TaskEither<PegError, PegProgress> getStatus({
    required PegDirection direction,
    required String orderId,
  }) {
    statusCalls++;
    final err = error;
    if (err != null) return TaskEither.left(err);
    final p = progress;
    if (p == null) return TaskEither.left(PegOrderNotFound(orderId));
    return TaskEither.right(p);
  }
}

class _RecordingStore implements PegStore {
  final List<String> terminals = [];
  bool failTerminal = false;

  @override
  Future<void> recordCreated(
    PegOrder order, {
    required BigInt amountSat,
  }) async {}

  @override
  Future<void> recordFunded(String orderId, String fundingTxId) async {}

  @override
  Future<void> recordTerminal(
    String orderId, {
    required PegPhase phase,
    String? payoutTxId,
    String? errorMessage,
  }) async {
    if (failTerminal) throw StateError('disk full');
    terminals.add('$orderId:${phase.name}');
  }
}

class _FakeRecovery implements PegRecoverySource {
  List<TrackedPeg> pegs = [];

  @override
  Future<List<TrackedPeg>> loadActivePegs() async => pegs;
}
