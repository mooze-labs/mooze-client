import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart';

import 'package:mooze_mobile/domain/entities/chain.dart';
import 'package:mooze_mobile/domain/entities/send_request.dart';
import 'package:mooze_mobile/domain/entities/transaction.dart';
import 'package:mooze_mobile/domain/entities/wallet_credentials.dart';
import 'package:mooze_mobile/domain/events/transaction_event.dart';
import 'package:mooze_mobile/domain/services/service_state.dart';
import 'package:mooze_mobile/infra/core/core_bitcoin_wallet_service.dart';

import 'core_test_fixtures.dart';

class _MockCore extends Mock implements MoozeCore {}

const _creds = WalletCredentials(
  mnemonic: 'abandon abandon abandon abandon abandon abandon '
      'abandon abandon abandon abandon abandon about',
  network: AppNetwork.mainnet,
);

void main() {
  setUpAll(() {
    registerFallbackValue(fallbackSendRequestDto);
    registerFallbackValue(txDto(id: 'fallback'));
  });

  late _MockCore core;
  late MemoryLogger logger;
  late CoreBitcoinWalletService service;

  setUp(() {
    core = _MockCore();
    logger = MemoryLogger();
    service = CoreBitcoinWalletService(
      core: core,
      logger: logger,
      clock: FixedClock(),
    );
    when(() => core.bitcoinConnect(mnemonic: any(named: 'mnemonic')))
        .thenAnswer((_) async {});
    when(() => core.bitcoinDisconnect()).thenAnswer((_) async {});
    when(() => core.bitcoinTakeEvents()).thenAnswer((_) async => []);
  });

  tearDown(() async {
    await service.dispose();
  });

  group('connect', () {
    test('success goes connecting -> connected', () async {
      final states = <ServiceLifecycle>[];
      final sub = service.state.listen((s) => states.add(s.lifecycle));

      final r = await service.connect(_creds);
      await Future<void>.delayed(Duration.zero);

      expect(r.isRight(), isTrue);
      expect(service.currentState.lifecycle, ServiceLifecycle.connected);
      expect(states, [
        ServiceLifecycle.uninitialized,
        ServiceLifecycle.connecting,
        ServiceLifecycle.connected,
      ]);
      verify(() => core.bitcoinConnect(mnemonic: _creds.mnemonic)).called(1);
      await sub.cancel();
    });

    test('second connect short-circuits', () async {
      await service.connect(_creds);
      final r = await service.connect(_creds);
      expect(r.isRight(), isTrue);
      verify(() => core.bitcoinConnect(mnemonic: any(named: 'mnemonic')))
          .called(1);
    });

    test('a CoreError moves the state to errored', () async {
      when(() => core.bitcoinConnect(mnemonic: any(named: 'mnemonic')))
          .thenThrow(const CoreError(
        kind: CoreErrorKind.service,
        message: 'wallet service failed on Bitcoin: bad descriptor',
      ));

      final r = await service.connect(_creds);

      final f = r.getLeft().toNullable()!;
      expect(f.message, 'bdk init failed: bad descriptor');
      expect(f.chain, ChainId.bitcoin);
      expect(service.currentState.lifecycle, ServiceLifecycle.errored);
      expect(service.currentState.failure?.message, f.message);
      expect(logger.hasTag('bitcoin.fail'), isTrue);
    });

    test('a failed core open becomes a connect failure', () async {
      final s = CoreBitcoinWalletService.deferred(
        core: Future<MoozeCore>.error(StateError('open failed')),
        logger: logger,
        clock: FixedClock(),
      );
      final r = await s.connect(_creds);
      expect(r.getLeft().toNullable()!.message,
          'bdk init failed: Bad state: open failed');
      expect(s.currentState.lifecycle, ServiceLifecycle.errored);
      await s.dispose();
    });

    test('a later connect clears the failure', () async {
      when(() => core.bitcoinConnect(mnemonic: any(named: 'mnemonic')))
          .thenThrow(const CoreError(kind: CoreErrorKind.other, message: 'x'));
      await service.connect(_creds);
      when(() => core.bitcoinConnect(mnemonic: any(named: 'mnemonic')))
          .thenAnswer((_) async {});

      final r = await service.connect(_creds);

      expect(r.isRight(), isTrue);
      expect(service.currentState.failure, isNull);
    });
  });

  group('not connected', () {
    test('every read and spend fails with "not connected"', () async {
      const req = SendRequest(
          chain: ChainId.bitcoin, destination: 'bc1q', amountSat: 1000);
      final results = [
        await service.sync(),
        await service.listTransactions(),
        await service.getBalance(),
        await service.getBlockHeight(),
        await service.estimateFee(req),
        await service.nextReceiveAddress(),
        await service.sendOnchain(req),
      ];
      for (final r in results) {
        expect(r.getLeft().toNullable()?.message, 'not connected');
      }
      verifyNever(() => core.bitcoinSync());
      verifyNever(() => core.bitcoinSend(request: any(named: 'request')));
    });
  });

  group('sync', () {
    setUp(() async {
      await service.connect(_creds);
    });

    test('emits TransactionEvents from take_events', () async {
      when(() => core.bitcoinSync()).thenAnswer(
          (_) async => syncDto(ChainDto.bitcoin, fetched: 2, changed: 1));
      when(() => core.bitcoinTakeEvents()).thenAnswer((_) async => [
            createdEvent(txDto(id: 'a')),
            TransactionEventDto(
              kind: TransactionEventKindDto.statusChanged,
              transaction: txDto(id: 'b', status: StatusDto.confirmed),
              observedAtMs: BigInt.from(1),
              previousStatus: StatusDto.pending,
              previousConfirmations: 0,
            ),
          ]);
      final events = <TransactionEvent>[];
      final sub = service.transactions.listen(events.add);

      final r = await service.sync();
      await Future<void>.delayed(Duration.zero);

      final outcome = r.getOrElse((_) => throw StateError('left'));
      expect(outcome.chain, ChainId.bitcoin);
      expect(outcome.fetched, 2);
      expect(outcome.changed, 1);
      expect(events.map((e) => e.kind), [
        TransactionEventKind.created,
        TransactionEventKind.statusChanged,
      ]);
      expect(events.last.previousStatus, TransactionStatus.pending);
      expect(service.currentState.lastSyncAt, FixedClock().now());
      await sub.cancel();
    });

    test('a CoreError maps to a ServiceFailure without changing state',
        () async {
      when(() => core.bitcoinSync()).thenThrow(const CoreError(
        kind: CoreErrorKind.service,
        message: 'wallet service failed on Bitcoin: bdk sync failed: eof',
      ));

      final r = await service.sync();

      expect(r.getLeft().toNullable()!.message, 'bdk sync failed: eof');
      expect(service.currentState.lifecycle, ServiceLifecycle.connected);
    });

    test('a network CoreError gets the operation prefix', () async {
      when(() => core.bitcoinSync()).thenThrow(
          const CoreError(kind: CoreErrorKind.network, message: 'network: x'));
      final r = await service.sync();
      expect(r.getLeft().toNullable()!.message, 'bdk sync failed: network: x');
    });

    test('times out on the Dart side', () async {
      final never = Completer<SyncOutcomeDto>();
      when(() => core.bitcoinSync()).thenAnswer((_) => never.future);

      final r = await service.sync(timeout: const Duration(milliseconds: 10));

      expect(r.getLeft().toNullable()!.message, 'bdk sync timeout');
      verifyNever(() => core.bitcoinTakeEvents());
    });
  });

  group('spend', () {
    setUp(() async {
      await service.connect(_creds);
    });

    test('rejects other chains and assets before the core', () async {
      final liquid = await service.sendOnchain(const SendRequest(
          chain: ChainId.liquid, destination: 'x', amountSat: 1));
      expect(liquid.getLeft().toNullable()!.message,
          'bitcoin service only handles Bitcoin on-chain sends (got: liquid)');
      final asset = await service.estimateFee(const SendRequest(
          chain: ChainId.bitcoin, destination: 'x', amountSat: 1, assetId: 'a'));
      expect(asset.getLeft().toNullable()!.message,
          'bitcoin service does not handle asset sends (got assetId: a)');
      final recv = await service.nextReceiveAddress(assetId: 'a');
      expect(recv.getLeft().toNullable()!.message,
          'bitcoin service does not handle asset receives (got assetId: a)');
    });

    test('sendOnchain returns the result and emits the created event',
        () async {
      final tx = txDto(
        id: 'sent',
        direction: DirectionDto.outgoing,
        source: SourceDto.bdk,
        amountSat: 5000,
        feeSat: 141,
      );
      when(() => core.bitcoinSend(request: any(named: 'request')))
          .thenAnswer((_) async => BroadcastResultDto(
                chain: ChainDto.bitcoin,
                txId: 'sent',
                transaction: tx,
                feePaidSat: BigInt.from(141),
              ));
      when(() => core.bitcoinTakeEvents())
          .thenAnswer((_) async => [createdEvent(tx)]);
      final events = <TransactionEvent>[];
      final sub = service.transactions.listen(events.add);

      final r = await service.sendOnchain(const SendRequest(
          chain: ChainId.bitcoin, destination: 'bc1q', amountSat: 5000));
      await Future<void>.delayed(Duration.zero);

      final res = r.getOrElse((_) => throw StateError('left'));
      expect(res.txId, 'sent');
      expect(res.feePaidSat, 141);
      expect(res.transaction.direction, TransactionDirection.outgoing);
      expect(events.single.transaction.id, 'sent');
      final captured = verify(
              () => core.bitcoinSend(request: captureAny(named: 'request')))
          .captured
          .single as SendRequestDto;
      expect(captured.destination, 'bc1q');
      expect(captured.amountSat, BigInt.from(5000));
      await sub.cancel();
    });

    test('getBlockHeight, balance, list and receive go through the core',
        () async {
      when(() => core.bitcoinBlockHeight()).thenAnswer((_) async => 900000);
      when(() => core.bitcoinBalance())
          .thenAnswer((_) async => balanceDto(ChainDto.bitcoin, {null: 7}));
      when(() => core.bitcoinTransactions())
          .thenAnswer((_) async => [txDto(id: 'x')]);
      when(() => core.bitcoinReceiveAddress(label: any(named: 'label')))
          .thenAnswer((_) async => const ReceiveAddressDto(
              chain: ChainDto.bitcoin, address: 'bc1qnew', label: 'l'));

      expect((await service.getBlockHeight()).getOrElse((_) => -1), 900000);
      expect(
          (await service.getBalance())
              .getOrElse((_) => throw StateError('left'))
              .totalSatForChain(ChainId.bitcoin),
          7);
      expect(
          (await service.listTransactions())
              .getOrElse((_) => const [])
              .single
              .id,
          'x');
      final addr = (await service.nextReceiveAddress(label: 'l'))
          .getOrElse((_) => throw StateError('left'));
      expect(addr.address, 'bc1qnew');
      expect(addr.label, 'l');
    });

    test('registerExternalBroadcast forwards to the core and emits', () async {
      final tx = Transaction(
        id: 'ext',
        chain: ChainId.bitcoin,
        direction: TransactionDirection.outgoing,
        status: TransactionStatus.pending,
        amountSat: 1,
        feeSat: 1,
        timestamp: DateTime(2026),
      );
      when(() => core.bitcoinRegisterExternalBroadcast(
              transaction: any(named: 'transaction')))
          .thenAnswer((_) async {});
      when(() => core.bitcoinTakeEvents())
          .thenAnswer((_) async => [createdEvent(txDto(id: 'ext'))]);
      final events = <TransactionEvent>[];
      final sub = service.transactions.listen(events.add);

      service.registerExternalBroadcast(tx);
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(events.single.transaction.id, 'ext');
      await sub.cancel();
    });

    test('registerExternalBroadcast ignores other chains', () async {
      service.registerExternalBroadcast(Transaction(
        id: 'l',
        chain: ChainId.liquid,
        direction: TransactionDirection.outgoing,
        status: TransactionStatus.pending,
        amountSat: 1,
        feeSat: 1,
        timestamp: DateTime(2026),
      ));
      await Future<void>.delayed(Duration.zero);
      verifyNever(() => core.bitcoinRegisterExternalBroadcast(
          transaction: any(named: 'transaction')));
    });
  });

  group('disconnect', () {
    test('goes disconnecting -> disconnected and drops the core wallet',
        () async {
      await service.connect(_creds);
      final states = <ServiceLifecycle>[];
      final sub = service.state.listen((s) => states.add(s.lifecycle));

      final r = await service.disconnect();
      await Future<void>.delayed(Duration.zero);

      expect(r.isRight(), isTrue);
      expect(states, [
        ServiceLifecycle.connected,
        ServiceLifecycle.disconnecting,
        ServiceLifecycle.disconnected,
      ]);
      verify(() => core.bitcoinDisconnect()).called(1);
      expect((await service.getBalance()).isLeft(), isTrue);
      await sub.cancel();
    });

    test('is a no-op when never connected', () async {
      final r = await service.disconnect();
      expect(r.isRight(), isTrue);
      verifyNever(() => core.bitcoinDisconnect());
    });
  });
}
