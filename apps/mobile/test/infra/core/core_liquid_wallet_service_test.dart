import 'dart:async';

import 'package:flutter_rust_bridge/flutter_rust_bridge.dart' show Int64List;
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart';

import 'package:mooze_mobile/domain/entities/asset.dart';
import 'package:mooze_mobile/domain/entities/chain.dart';
import 'package:mooze_mobile/domain/entities/send_request.dart';
import 'package:mooze_mobile/domain/entities/wallet_credentials.dart';
import 'package:mooze_mobile/domain/events/transaction_event.dart';
import 'package:mooze_mobile/domain/failures/failure.dart';
import 'package:mooze_mobile/domain/repositories/secure_credential_store.dart';
import 'package:mooze_mobile/domain/services/service_state.dart';
import 'package:mooze_mobile/infra/core/core_liquid_wallet_service.dart';

import 'core_test_fixtures.dart';

class _MockCore extends Mock implements MoozeCore {}

class _MockCredentialStore extends Mock implements SecureCredentialStore {}

const _mnemonic = 'abandon abandon abandon abandon abandon abandon '
    'abandon abandon abandon abandon abandon about';
const _creds =
    WalletCredentials(mnemonic: _mnemonic, network: AppNetwork.mainnet);

BroadcastResultDto _broadcast(String txid) => BroadcastResultDto(
      chain: ChainDto.liquid,
      txId: txid,
      transaction: txDto(
        id: txid,
        chain: ChainDto.liquid,
        direction: DirectionDto.outgoing,
        assetId: lbtcAssetId,
        source: SourceDto.lwk,
      ),
      feePaidSat: BigInt.from(26),
    );

void main() {
  setUpAll(() {
    registerFallbackValue(fallbackSendRequestDto);
    registerFallbackValue(Int64List(0));
    registerFallbackValue(BigInt.zero);
  });

  late _MockCore core;
  late _MockCredentialStore store;
  late MemoryLogger logger;
  late CoreLiquidWalletService service;

  setUp(() {
    core = _MockCore();
    store = _MockCredentialStore();
    logger = MemoryLogger();
    service = CoreLiquidWalletService(
      core: core,
      logger: logger,
      clock: FixedClock(),
      credentialStore: store,
    );
    when(() => core.liquidConnect(mnemonic: any(named: 'mnemonic')))
        .thenAnswer((_) async {});
    when(() => core.liquidDisconnect()).thenAnswer((_) async {});
    when(() => core.liquidTakeEvents()).thenAnswer((_) async => []);
    when(() => store.load()).thenAnswer((_) async => const Right(_creds));
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
      expect(states, [
        ServiceLifecycle.uninitialized,
        ServiceLifecycle.connecting,
        ServiceLifecycle.connected,
      ]);
      await sub.cancel();
    });

    test('a core init error keeps the lwk text and moves to errored',
        () async {
      when(() => core.liquidConnect(mnemonic: any(named: 'mnemonic')))
          .thenThrow(const CoreError(
        kind: CoreErrorKind.service,
        message: 'wallet service failed on Liquid: lwk init failed: bad',
      ));

      final r = await service.connect(_creds);

      expect(r.getLeft().toNullable()!.message, 'lwk init failed: bad');
      expect(service.currentState.lifecycle, ServiceLifecycle.errored);
      expect(logger.hasTag('liquid.connect.threw'), isTrue);
    });

    test('a credential error gets the lwk init prefix', () async {
      when(() => core.liquidConnect(mnemonic: any(named: 'mnemonic')))
          .thenThrow(const CoreError(
        kind: CoreErrorKind.credential,
        message: 'credentials: mnemonic is empty',
      ));
      final r = await service.connect(_creds);
      expect(r.getLeft().toNullable()!.message,
          'lwk init failed: credentials: mnemonic is empty');
    });

    test('a disconnect during connect cancels it', () async {
      final gate = Completer<void>();
      when(() => core.liquidConnect(mnemonic: any(named: 'mnemonic')))
          .thenAnswer((_) => gate.future);

      final connecting = service.connect(_creds);
      await Future<void>.delayed(Duration.zero);
      final disconnecting = service.disconnect();
      gate.complete();

      final r = await connecting;
      expect(r.getLeft().toNullable()!.message,
          'connect cancelled: shutdown in progress');
      await disconnecting;
      // One drop for the cancelled connect, one for the disconnect.
      verify(() => core.liquidDisconnect()).called(2);
      expect(service.currentState.lifecycle, ServiceLifecycle.disconnected);
    });
  });

  group('not connected', () {
    test('every call fails with "not connected"', () async {
      const req = SendRequest(
          chain: ChainId.liquid, destination: 'lq1', amountSat: 1000);
      final results = <Either<ServiceFailure, Object?>>[
        await service.sync(),
        await service.listTransactions(),
        await service.getBalance(),
        await service.getUtxos(),
        await service.signSwapPset(pset: 'p', mnemonic: _mnemonic),
        await service.getReceiveAddress(),
        await service.buildLbtcSend(destination: 'lq1', amountSat: BigInt.one),
        await service.signAndBroadcastPset(pset: 'p', mnemonic: _mnemonic),
        await service.estimateFee(req),
        await service.nextReceiveAddress(),
        await service.sendOnchain(req),
        await service.refreshBalance(),
        await service.applyOptimisticBalanceDelta(deltas: {'a': 1}),
      ];
      for (final r in results) {
        expect(r.getLeft().toNullable()?.message, 'not connected');
      }
      verifyNever(() => core.liquidSync());
    });
  });

  group('connected', () {
    setUp(() async {
      await service.connect(_creds);
    });

    test('sync emits TransactionEvents from take_events', () async {
      when(() => core.liquidSync()).thenAnswer(
          (_) async => syncDto(ChainDto.liquid, fetched: 3, changed: 1));
      when(() => core.liquidTakeEvents()).thenAnswer((_) async =>
          [createdEvent(txDto(id: 'in', chain: ChainDto.liquid))]);
      final events = <TransactionEvent>[];
      final sub = service.transactions.listen(events.add);

      final r = await service.sync();
      await Future<void>.delayed(Duration.zero);

      expect(r.getOrElse((_) => throw StateError('left')).fetched, 3);
      expect(events.single.transaction.chain, ChainId.liquid);
      expect(service.currentState.lastSyncAt, isNotNull);
      await sub.cancel();
    });

    test('sync timeout and errors map like the old service', () async {
      when(() => core.liquidSync())
          .thenAnswer((_) => Completer<SyncOutcomeDto>().future);
      final timedOut =
          await service.sync(timeout: const Duration(milliseconds: 10));
      expect(timedOut.getLeft().toNullable()!.message, 'lwk sync timeout');

      when(() => core.liquidSync()).thenThrow(const CoreError(
        kind: CoreErrorKind.service,
        message: 'wallet service failed on Liquid: lwk sync failed: eof',
      ));
      final failed = await service.sync();
      expect(failed.getLeft().toNullable()!.message, 'lwk sync failed: eof');
    });

    test('buildLbtcSend validates in Dart, then drains pre-sync events',
        () async {
      final zero =
          await service.buildLbtcSend(destination: 'lq1', amountSat: BigInt.zero);
      expect(zero.getLeft().toNullable()!.message, 'amount must be positive');
      final empty =
          await service.buildLbtcSend(destination: ' ', amountSat: BigInt.one);
      expect(empty.getLeft().toNullable()!.message, 'destination is empty');

      when(() => core.liquidBuildLbtcSend(
            destination: any(named: 'destination'),
            amountSat: any(named: 'amountSat'),
            feeRateSatPerVb: any(named: 'feeRateSatPerVb'),
            drain: any(named: 'drain'),
          )).thenAnswer((_) async => LiquidSendDraftDto(
            pset: 'pset',
            destination: 'lq1',
            amountSat: BigInt.from(900),
            feeSat: BigInt.from(26),
            feeRateSatPerKvb: 100,
            drain: true,
          ));
      when(() => core.liquidTakeEvents()).thenAnswer((_) async =>
          [createdEvent(txDto(id: 'presync', chain: ChainDto.liquid))]);
      final events = <TransactionEvent>[];
      final sub = service.transactions.listen(events.add);

      final r = await service.buildLbtcSend(
          destination: 'lq1', amountSat: BigInt.zero, drain: true);
      await Future<void>.delayed(Duration.zero);

      final draft = r.getOrElse((_) => throw StateError('left'));
      expect(draft.amountSat, BigInt.from(900));
      expect(draft.feeSat, BigInt.from(26));
      expect(events.single.transaction.id, 'presync');
      await sub.cancel();
    });

    test('sendOnchain passes the stored mnemonic and emits the event',
        () async {
      when(() => core.liquidSend(
            request: any(named: 'request'),
            mnemonic: any(named: 'mnemonic'),
          )).thenAnswer((_) async => _broadcast('txid1'));
      when(() => core.liquidTakeEvents()).thenAnswer((_) async => [
            createdEvent(_broadcast('txid1').transaction),
          ]);
      final events = <TransactionEvent>[];
      final sub = service.transactions.listen(events.add);

      final r = await service.sendOnchain(const SendRequest(
          chain: ChainId.liquid, destination: 'lq1', amountSat: 1000));
      await Future<void>.delayed(Duration.zero);

      final res = r.getOrElse((_) => throw StateError('left'));
      expect(res.txId, 'txid1');
      expect(res.chain, ChainId.liquid);
      expect(res.feePaidSat, 26);
      expect(events.single.kind, TransactionEventKind.created);
      verify(() => core.liquidSend(
            request: any(named: 'request'),
            mnemonic: _mnemonic,
          )).called(1);
      await sub.cancel();
    });

    test('sendOnchain without a stored mnemonic sends an empty one', () async {
      when(() => store.load()).thenAnswer(
          (_) async => const Left(CredentialFailure('missing')));
      when(() => core.liquidSend(
            request: any(named: 'request'),
            mnemonic: any(named: 'mnemonic'),
          )).thenThrow(const CoreError(
        kind: CoreErrorKind.service,
        message: 'wallet service failed on Liquid: mnemonic not available',
      ));

      final r = await service.sendOnchain(const SendRequest(
          chain: ChainId.liquid, destination: 'lq1', amountSat: 1000));

      expect(r.getLeft().toNullable()!.message, 'mnemonic not available');
      verify(() => core.liquidSend(
            request: any(named: 'request'),
            mnemonic: '',
          )).called(1);
    });

    test('sendOnchain rejects bad requests before the core', () async {
      final wrongChain = await service.sendOnchain(const SendRequest(
          chain: ChainId.bitcoin, destination: 'bc1', amountSat: 1));
      expect(wrongChain.getLeft().toNullable()!.message,
          'liquid service only handles Liquid sends (got: bitcoin)');
      final empty = await service.estimateFee(const SendRequest(
          chain: ChainId.liquid, destination: '  ', amountSat: 1));
      expect(empty.getLeft().toNullable()!.message, 'destination is empty');
      verifyNever(() => core.liquidSend(
            request: any(named: 'request'),
            mnemonic: any(named: 'mnemonic'),
          ));
    });

    test('sendOnchain without a credential store fails', () async {
      final s = CoreLiquidWalletService(
          core: core, logger: logger, clock: FixedClock());
      await s.connect(_creds);
      final r = await s.sendOnchain(const SendRequest(
          chain: ChainId.liquid, destination: 'lq1', amountSat: 1));
      expect(r.getLeft().toNullable()!.message, 'no credential store');
      await s.dispose();
    });

    test('signAndBroadcastPset validates and maps core errors', () async {
      final noPset =
          await service.signAndBroadcastPset(pset: ' ', mnemonic: _mnemonic);
      expect(noPset.getLeft().toNullable()!.message, 'pset is empty');
      final noMn = await service.signAndBroadcastPset(pset: 'p', mnemonic: '');
      expect(noMn.getLeft().toNullable()!.message, 'mnemonic is empty');

      when(() => core.liquidSignAndBroadcast(
            pset: any(named: 'pset'),
            mnemonic: any(named: 'mnemonic'),
          )).thenThrow(const CoreError(
        kind: CoreErrorKind.service,
        message: 'wallet service failed on Liquid: lwk signTx failed: bad pset',
      ));
      final r = await service.signAndBroadcastPset(pset: 'p', mnemonic: 'm');
      expect(r.getLeft().toNullable()!.message, 'lwk signTx failed: bad pset');
      expect(r.getLeft().toNullable()!.chain, ChainId.liquid);
    });

    test('signAndBroadcastPset returns the txid', () async {
      when(() => core.liquidSignAndBroadcast(
            pset: any(named: 'pset'),
            mnemonic: any(named: 'mnemonic'),
          )).thenAnswer((_) async => 'txid2');
      final r = await service.signAndBroadcastPset(pset: 'p', mnemonic: 'm');
      expect(r.getOrElse((_) => ''), 'txid2');
      verify(() => core.liquidTakeEvents()).called(1);
    });

    test('swap surface goes through the core', () async {
      when(() => core.liquidUtxos()).thenAnswer((_) async => [
            LiquidUtxoDto(
              txid: 't',
              vout: 1,
              assetId: lbtcAssetId,
              assetBlindingFactor: 'a',
              valueSat: BigInt.from(10),
              valueBlindingFactor: 'v',
            ),
          ]);
      when(() => core.liquidSignSwapPset(
            pset: any(named: 'pset'),
            mnemonic: any(named: 'mnemonic'),
          )).thenAnswer((_) async => 'signed');
      when(() => core.liquidReceiveAddress(
            assetId: any(named: 'assetId'),
            label: any(named: 'label'),
          )).thenAnswer((inv) async => ReceiveAddressDto(
            chain: ChainDto.liquid,
            address: inv.namedArguments[#assetId] == null
                ? 'lq1bare'
                : 'liquidnetwork:lq1bare?assetid=${inv.namedArguments[#assetId]}',
            assetId: inv.namedArguments[#assetId] as String?,
          ));

      expect((await service.getUtxos()).getOrElse((_) => []).single.vout, 1);
      expect(
          (await service.signSwapPset(pset: 'p', mnemonic: 'm'))
              .getOrElse((_) => ''),
          'signed');
      expect((await service.getReceiveAddress()).getOrElse((_) => ''),
          'lq1bare');
      final asset = (await service.nextReceiveAddress(assetId: usdtAssetId))
          .getOrElse((_) => throw StateError('left'));
      expect(asset.address, 'liquidnetwork:lq1bare?assetid=$usdtAssetId');
      expect(asset.assetId, usdtAssetId);
    });

    test('applyOptimisticBalanceDelta sends paired lists to the core',
        () async {
      when(() => core.liquidApplyBalanceDelta(
                assetIds: any(named: 'assetIds'),
                deltas: any(named: 'deltas'),
              ))
          .thenAnswer((_) async =>
              balanceDto(ChainDto.liquid, {lbtcAssetId: 900, usdtAssetId: 5}));

      final r = await service.applyOptimisticBalanceDelta(
          deltas: {lbtcAssetId: -100, usdtAssetId: 5});

      final b = r.getOrElse((_) => throw StateError('left'));
      expect(b.assets, hasLength(2));
      final captured = verify(() => core.liquidApplyBalanceDelta(
            assetIds: captureAny(named: 'assetIds'),
            deltas: captureAny(named: 'deltas'),
          )).captured;
      expect(captured[0], [lbtcAssetId, usdtAssetId]);
      expect((captured[1] as Int64List).inner.toList(), [-100, 5]);
    });

    test('empty deltas return the current balance', () async {
      when(() => core.liquidBalance())
          .thenAnswer((_) async => balanceDto(ChainDto.liquid, {lbtcAssetId: 1}));
      final r = await service.applyOptimisticBalanceDelta(deltas: {});
      expect(r.isRight(), isTrue);
      verifyNever(() => core.liquidApplyBalanceDelta(
            assetIds: any(named: 'assetIds'),
            deltas: any(named: 'deltas'),
          ));
    });

    test('refreshBalance maps a core error', () async {
      when(() => core.liquidRefreshBalance()).thenThrow(const CoreError(
          kind: CoreErrorKind.storage, message: 'storage: locked'));
      final r = await service.refreshBalance();
      expect(r.getLeft().toNullable()!.message,
          'lwk refreshBalance failed: storage: locked');
      expect(logger.hasTag('liquid.refresh_balance.failed'), isTrue);
    });

    test('disconnect goes disconnecting -> disconnected', () async {
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
      verify(() => core.liquidDisconnect()).called(1);
      await sub.cancel();
    });
  });
}
