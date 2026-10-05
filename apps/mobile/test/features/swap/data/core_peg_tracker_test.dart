import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart';

import 'package:mooze_mobile/features/swap/data/repositories/core_peg_tracker.dart';
import 'package:mooze_mobile/features/swap/data/services/core_sideswap_session.dart';
import 'package:mooze_mobile/features/swap/domain/entities/peg.dart';
import 'package:mooze_mobile/features/swap/domain/usecases/peg_tracker.dart';

class _MockCore extends Mock implements MoozeCore {}

final _now = DateTime.fromMillisecondsSinceEpoch(1700000000000);

TrackedPegDto _peg(
  String id, {
  PegPhaseDto phase = PegPhaseDto.awaitingDeposit,
  int? confirmations,
}) =>
    TrackedPegDto(
      orderId: id,
      direction: PegDirectionDto.pegOut,
      phase: phase,
      amountSat: BigInt.from(50000),
      depositAddress: 'deposit-$id',
      fundingTxId: 'funding-$id',
      confirmations: confirmations,
      requiredConfirmations: confirmations == null ? null : 2,
    );

PegRefreshDto _refresh(List<TrackedPegDto> pegs, {int? wakeupInMs}) =>
    PegRefreshDto(
      pegs: pegs,
      changed: const [],
      finished: const [],
      nextWakeupMs: wakeupInMs == null
          ? null
          : BigInt.from(_now.millisecondsSinceEpoch + wakeupInMs),
    );

void main() {
  late _MockCore core;
  late CorePegTracker tracker;

  setUp(() {
    core = _MockCore();
    when(() => core.sideswapConnect(
          apiKey: any(named: 'apiKey'),
          url: any(named: 'url'),
        )).thenAnswer((_) async {});
    when(() => core.pegUntrack(orderId: any(named: 'orderId')))
        .thenAnswer((_) async {});
    tracker = CorePegTracker(
      session: CoreSideswapSession(core: Future.value(core), apiKey: 'key'),
      walletId: Future.value('wallet-1'),
      now: () => _now,
      retryDelay: const Duration(milliseconds: 20),
    );
  });

  tearDown(() => tracker.dispose());

  test('restore resumes the stored pegs and polls them', () async {
    when(() => core.pegRestore(walletId: 'wallet-1'))
        .thenAnswer((_) async => [_peg('a')]);
    when(() => core.pegRefreshDue(walletId: 'wallet-1')).thenAnswer(
      (_) async => _refresh(
        [_peg('a', phase: PegPhaseDto.detected, confirmations: 1)],
        wakeupInMs: 30000,
      ),
    );

    await tracker.restore();

    final peg = tracker.current.single;
    expect(peg.phase, PegPhase.detected);
    expect(peg.confirmations, 1);
    expect(peg.requiredConfirmations, 2);
    expect(tracker.hasScheduledRefresh, isTrue);
  });

  test('the next refresh fires at nextWakeupMs', () async {
    var calls = 0;
    when(() => core.pegRefreshDue(walletId: 'wallet-1')).thenAnswer((_) async {
      calls++;
      return calls == 1
          ? _refresh([_peg('a')], wakeupInMs: 15)
          : _refresh([_peg('a', phase: PegPhaseDto.completed)]);
    });

    await tracker.refresh();
    expect(calls, 1);
    await Future<void>.delayed(const Duration(milliseconds: 60));

    expect(calls, 2);
    expect(tracker.current.single.phase, PegPhase.completed);
    expect(tracker.hasScheduledRefresh, isFalse,
        reason: 'no wakeup means nothing left to poll');
  });

  test('track shows the peg at once and polls now', () async {
    when(() => core.pegRefreshDue(walletId: 'wallet-1')).thenAnswer(
      (_) async => _refresh([_peg('b')], wakeupInMs: 300000),
    );
    final emitted = <List<TrackedPeg>>[];
    tracker.pegs.listen(emitted.add);

    tracker.track(
      TrackedPeg(
        orderId: 'b',
        direction: PegDirection.pegOut,
        phase: PegPhase.awaitingDeposit,
        amountSat: BigInt.from(50000),
        depositAddress: 'deposit-b',
      ),
    );
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(emitted.first.single.orderId, 'b');
    verify(() => core.pegRefreshDue(walletId: 'wallet-1')).called(1);
  });

  test('a failed refresh retries while a peg is pending', () async {
    when(() => core.pegRestore(walletId: 'wallet-1'))
        .thenAnswer((_) async => [_peg('a')]);
    var calls = 0;
    when(() => core.pegRefreshDue(walletId: 'wallet-1')).thenAnswer((_) async {
      calls++;
      if (calls == 1) throw StateError('socket down');
      return _refresh([_peg('a')]);
    });

    await tracker.restore();
    await Future<void>.delayed(const Duration(milliseconds: 60));

    expect(calls, 2);
  });

  test('untrack removes the peg and stops the core tracking', () async {
    when(() => core.pegRestore(walletId: 'wallet-1'))
        .thenAnswer((_) async => [_peg('a'), _peg('b')]);
    when(() => core.pegRefreshDue(walletId: 'wallet-1'))
        .thenAnswer((_) async => _refresh([_peg('a'), _peg('b')]));
    await tracker.restore();

    tracker.untrack('a');
    await Future<void>.delayed(Duration.zero);

    expect(tracker.current.map((p) => p.orderId), ['b']);
    verify(() => core.pegUntrack(orderId: 'a')).called(1);
  });

  test('dispose cancels the timer and closes the stream', () async {
    when(() => core.pegRefreshDue(walletId: 'wallet-1')).thenAnswer(
      (_) async => _refresh([_peg('a')], wakeupInMs: 10),
    );
    await tracker.refresh();
    final done = Completer<void>();
    tracker.pegs.listen(null, onDone: done.complete);

    tracker.dispose();
    clearInteractions(core);
    await Future<void>.delayed(const Duration(milliseconds: 40));

    await done.future.timeout(const Duration(seconds: 1));
    expect(tracker.hasScheduledRefresh, isFalse);
    verifyNever(() => core.pegRefreshDue(walletId: any(named: 'walletId')));
  });
}
