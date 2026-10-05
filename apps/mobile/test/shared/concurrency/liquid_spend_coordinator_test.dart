import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:mooze_mobile/shared/concurrency/liquid_spend_coordinator.dart';

void main() {
  group('LiquidSpendCoordinator', () {
    test('serialises overlapping spends — no interleaving', () async {
      final coordinator = LiquidSpendCoordinator();
      final events = <String>[];

      Future<void> spend(String name, Duration work) =>
          coordinator.protect(name, () async {
            events.add('$name:start');
            await Future<void>.delayed(work);
            events.add('$name:end');
          });

      // B is faster but starts second: if the lock works it still runs last.
      final a = spend('A', const Duration(milliseconds: 60));
      final b = spend('B', const Duration(milliseconds: 1));
      await Future.wait([a, b]);

      expect(events, ['A:start', 'A:end', 'B:start', 'B:end']);
    });

    test('runs beforeSpend inside the lock, ahead of the body', () async {
      // This ordering is the whole point: re-syncing before selection is what
      // stops a queued spend from building against a UTXO set that the
      // previous holder already spent from.
      final coordinator = LiquidSpendCoordinator();
      final order = <String>[];

      await coordinator.protect(
        'peg-out',
        () async => order.add('body'),
        beforeSpend: () async => order.add('sync'),
        afterSpend: () async => order.add('resync'),
      );

      expect(order, ['sync', 'body', 'resync']);
    });

    test('afterSpend still runs when the body throws', () async {
      // A throw after broadcast still means coins moved — the next waiter
      // must not select the spent UTXO.
      final coordinator = LiquidSpendCoordinator();
      var resynced = false;

      await expectLater(
        coordinator.protect(
          'peg-out',
          () async => throw StateError('broadcast blew up'),
          afterSpend: () async => resynced = true,
        ),
        throwsStateError,
      );

      expect(resynced, isTrue);
    });

    test('a resync failure never masks the spend outcome', () async {
      final coordinator = LiquidSpendCoordinator();

      final result = await coordinator.protect(
        'peg-out',
        () async => 'txid-abc',
        afterSpend: () async => throw StateError('electrum down'),
      );

      expect(result, 'txid-abc');
    });

    test('releases the lock after a failing section', () async {
      final coordinator = LiquidSpendCoordinator();

      await expectLater(
        coordinator.protect('A', () async => throw StateError('boom')),
        throwsStateError,
      );

      expect(coordinator.isBusy, isFalse);
      expect(await coordinator.protect('B', () async => 42), 42);
      expect(coordinator.currentHolder, isNull);
    });

    test('names the current holder while a section runs', () async {
      final coordinator = LiquidSpendCoordinator();
      final gate = Completer<void>();
      String? seen;

      final running = coordinator.protect('peg-out', () async {
        seen = coordinator.currentHolder;
        await gate.future;
      });

      await Future<void>.delayed(Duration.zero);
      expect(coordinator.isBusy, isTrue);
      gate.complete();
      await running;

      expect(seen, 'peg-out');
    });

    test('times out waiting, and reports who is holding the lock', () async {
      final coordinator = LiquidSpendCoordinator(
        acquireTimeout: const Duration(milliseconds: 30),
      );
      final gate = Completer<void>();

      final holder = coordinator.protect('asset-swap', () async => gate.future);
      await Future<void>.delayed(Duration.zero);

      Object? caught;
      try {
        await coordinator.protect('peg-out', () async => 'never');
      } catch (e) {
        caught = e;
      }

      expect(caught, isA<LiquidSpendLockTimeout>());
      final timeout = caught as LiquidSpendLockTimeout;
      expect(timeout.waiter, 'peg-out');
      expect(timeout.holder, 'asset-swap');
      expect(timeout.diagnostic, contains('asset-swap'));
      // User-facing string must not leak internals.
      expect(timeout.toString(), contains('Outra operação Liquid'));

      gate.complete();
      await holder;
    });

    test('a timed-out waiter still runs later and does not leak an '
        'unhandled error', () async {
      // The mutex is FIFO and cannot cancel a queued section. Giving up on
      // *waiting* must not turn that section's eventual failure into an
      // unhandled async error that crashes the zone.
      final coordinator = LiquidSpendCoordinator(
        acquireTimeout: const Duration(milliseconds: 20),
      );
      final gate = Completer<void>();
      var queuedRan = false;

      final holder = coordinator.protect('holder', () async => gate.future);
      await Future<void>.delayed(Duration.zero);

      await expectLater(
        coordinator.protect('queued', () async {
          queuedRan = true;
          throw StateError('late failure');
        }),
        throwsA(isA<LiquidSpendLockTimeout>()),
      );

      gate.complete();
      await holder;
      // Let the detached section run to completion.
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(queuedRan, isTrue, reason: 'queued section should still execute');
    });

    test('exposes a process-wide singleton', () {
      expect(
        identical(
          LiquidSpendCoordinator.instance,
          LiquidSpendCoordinator.instance,
        ),
        isTrue,
      );
    });
  });
}
