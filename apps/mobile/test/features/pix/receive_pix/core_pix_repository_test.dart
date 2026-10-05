import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart';

import 'package:mooze_mobile/features/pix/receive_pix/data/models/pix_status_event.dart';
import 'package:mooze_mobile/features/pix/receive_pix/data/repositories/core_pix_repository.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

class _MockCore extends Mock implements MoozeCore {}

PixDepositDto _deposit(
  String id, {
  DepositStatusDto status = DepositStatusDto.pending,
  int? assetAmount,
}) =>
    PixDepositDto(
      depositId: id,
      pixKey: 'qr-$id',
      assetId: Asset.depix.id,
      amountInCents: BigInt.from(5000),
      network: 'liquid',
      status: status,
      createdAtMs: BigInt.from(1700000000000),
      blockchainTxid: assetAmount == null ? null : 'tx-$id',
      assetAmount: assetAmount == null ? null : BigInt.from(assetAmount),
    );

void main() {
  setUpAll(() => registerFallbackValue(BigInt.zero));

  late _MockCore core;
  late CorePixRepository repo;

  void stubCreate([PixDepositDto? dto]) => when(
        () => core.pixCreateDeposit(
          amountInCents: any(named: 'amountInCents'),
          assetId: any(named: 'assetId'),
          taxIdNumber: any(named: 'taxIdNumber'),
          address: any(named: 'address'),
        ),
      ).thenAnswer((_) async => dto ?? _deposit('dep-1'));

  setUp(() {
    core = _MockCore();
    when(() => core.pixCancelPolls()).thenAnswer((_) async {});
    repo = CorePixRepository(
      core: Future.value(core),
      pollInterval: const Duration(milliseconds: 10),
    );
  });

  tearDown(() => repo.dispose());

  group('newDeposit', () {
    test('creates the deposit in the core with a null address', () async {
      stubCreate();
      when(() => core.pixPollTick()).thenAnswer((_) async => []);
      when(() => core.pixActivePolls()).thenAnswer((_) async => 1);

      final events = <PixStatusEvent>[];
      repo.statusUpdates.listen(events.add);

      final result = await repo
          .newDeposit(5000, asset: Asset.lbtc, taxIdNumber: '52998224725')
          .run();

      final deposit = result.getRight().toNullable()!;
      expect(deposit.depositId, 'dep-1');
      expect(deposit.pixKey, 'qr-dep-1');
      expect(deposit.asset, Asset.depix);
      expect(deposit.amountInCents, 5000);
      expect(deposit.status, DepositStatus.pending);
      expect(
        deposit.createdAt,
        DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );
      verify(
        () => core.pixCreateDeposit(
          amountInCents: BigInt.from(5000),
          assetId: Asset.lbtc.id,
          taxIdNumber: '52998224725',
          address: null,
        ),
      ).called(1);

      await Future<void>.delayed(Duration.zero);
      expect(events.first.depositId, 'dep-1');
      expect(events.first.status, DepositStatus.pending);
      expect(repo.isPolling, isTrue);
    });

    test('returns the core error text and does not poll', () async {
      when(
        () => core.pixCreateDeposit(
          amountInCents: any(named: 'amountInCents'),
          assetId: any(named: 'assetId'),
          taxIdNumber: any(named: 'taxIdNumber'),
          address: any(named: 'address'),
        ),
      ).thenThrow(
        const CoreError(
          kind: CoreErrorKind.network,
          message: 'Não foi possível conectar ao servidor.',
        ),
      );

      final result = await repo.newDeposit(5000).run();

      expect(
        result.getLeft().toNullable(),
        'Não foi possível conectar ao servidor.',
      );
      expect(repo.isPolling, isFalse);
    });
  });

  group('status polling', () {
    test('forwards tick events and stops when the core polls nothing',
        () async {
      stubCreate();
      when(() => core.pixPollTick()).thenAnswer(
        (_) async => [
          PixStatusEventDto(
            depositId: 'dep-1',
            status: DepositStatusDto.depixSent,
            blockchainTxid: 'tx-1',
            assetAmount: BigInt.from(4800),
          ),
        ],
      );
      when(() => core.pixActivePolls()).thenAnswer((_) async => 0);

      final events = <PixStatusEvent>[];
      repo.statusUpdates.listen(events.add);
      await repo.newDeposit(5000).run();

      await Future<void>.delayed(const Duration(milliseconds: 60));

      final update = events.firstWhere(
        (e) => e.status == DepositStatus.depixSent,
      );
      expect(update.blockchainTxid, 'tx-1');
      expect(update.assetAmount, 4800);
      expect(repo.isPolling, isFalse);
      verify(() => core.pixPollTick()).called(1);
    });

    test('a failed tick keeps polling', () async {
      stubCreate();
      var calls = 0;
      when(() => core.pixPollTick()).thenAnswer((_) async {
        calls++;
        if (calls == 1) throw StateError('offline');
        return [];
      });
      when(() => core.pixActivePolls()).thenAnswer((_) async => 1);

      await repo.newDeposit(5000).run();
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(calls, greaterThan(1));
      expect(repo.isPolling, isTrue);
    });

    test('dispose cancels the timer and the core polls', () async {
      stubCreate();
      when(() => core.pixPollTick()).thenAnswer((_) async => []);
      when(() => core.pixActivePolls()).thenAnswer((_) async => 1);

      await repo.newDeposit(5000).run();
      expect(repo.isPolling, isTrue);

      repo.dispose();
      repo.dispose(); // idempotent
      await Future<void>.delayed(Duration.zero);
      clearInteractions(core);
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(repo.isPolling, isFalse);
      verifyNever(() => core.pixPollTick());
    });
  });

  group('reads', () {
    test('getDeposit maps a stored deposit, or none', () async {
      when(() => core.pixGetDeposit(depositId: 'dep-1')).thenAnswer(
        (_) async => _deposit(
          'dep-1',
          status: DepositStatusDto.finished,
          assetAmount: 4800,
        ),
      );
      when(() => core.pixGetDeposit(depositId: 'nope'))
          .thenAnswer((_) async => null);

      final found = (await repo.getDeposit('dep-1').run())
          .getRight()
          .toNullable()!
          .toNullable()!;
      expect(found.status, DepositStatus.finished);
      expect(found.assetAmount, BigInt.from(4800));
      expect(found.blockchainTxid, 'tx-dep-1');

      final missing =
          (await repo.getDeposit('nope').run()).getRight().toNullable()!;
      expect(missing.isNone(), isTrue);
    });

    test('getHistory pages through the core history', () async {
      when(() => core.pixHistory(limit: 50, offset: 50))
          .thenAnswer((_) async => [_deposit('a'), _deposit('b')]);

      final page = await repo.getHistory(limit: 50, offset: 50).run();

      expect(
        page.getRight().toNullable()!.map((d) => d.depositId),
        ['a', 'b'],
      );
    });

    test('getDeposits and updateDepositDetails map the core lists', () async {
      when(() => core.pixListDeposits(limit: null, offset: null))
          .thenAnswer((_) async => [_deposit('a')]);
      when(() => core.pixUpdateDepositDetails(depositIds: ['a'])).thenAnswer(
        (_) async => [_deposit('a', status: DepositStatusDto.expired)],
      );

      final all = await repo.getDeposits().run();
      final updated = await repo.updateDepositDetails(['a']).run();

      expect(all.getRight().toNullable()!.single.depositId, 'a');
      expect(
        updated.getRight().toNullable()!.single.status,
        DepositStatus.expired,
      );
    });
  });

  test('every core status maps to the app status of the same name', () {
    for (final dto in DepositStatusDto.values) {
      expect(DepositStatus.values.byName(dto.name).name, dto.name);
    }
  });

  test('a core that fails to open turns every call into a Left', () async {
    final failing = CorePixRepository(
      core: Future<MoozeCore>.error(StateError('no core')),
    );
    addTearDown(failing.dispose);

    final result = await failing.getDeposits().run();

    expect(result.isLeft(), isTrue);
  });

  test('statusUpdates closes on dispose and the core stops polling', () async {
    final done = Completer<void>();
    repo.statusUpdates.listen(null, onDone: done.complete);

    repo.dispose();

    await done.future.timeout(const Duration(seconds: 1));
    await Future<void>.delayed(Duration.zero);
    verify(() => core.pixCancelPolls()).called(1);
  });
}
