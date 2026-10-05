import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart';

import 'package:mooze_mobile/domain/entities/chain.dart';
import 'package:mooze_mobile/domain/entities/fee_estimate.dart';
import 'package:mooze_mobile/domain/entities/send_request.dart';
import 'package:mooze_mobile/domain/entities/transaction.dart';
import 'package:mooze_mobile/domain/events/transaction_event.dart';
import 'package:mooze_mobile/domain/failures/failure.dart';
import 'package:mooze_mobile/infra/core/core_dto_mapper.dart';

import 'core_test_fixtures.dart';

void main() {
  group('enums', () {
    test('chain round-trips', () {
      for (final c in ChainId.values) {
        expect(chainFromDto(chainToDto(c)), c);
      }
    });

    test('direction, status and source round-trip', () {
      for (final d in TransactionDirection.values) {
        expect(directionFromDto(directionToDto(d)), d);
      }
      for (final s in TransactionStatus.values) {
        expect(statusFromDto(statusToDto(s)), s);
      }
      for (final s in TransactionSource.values) {
        expect(sourceFromDto(sourceToDto(s)), s);
      }
    });

    test('fee priority round-trips', () {
      for (final p in FeePriority.values) {
        expect(feePriorityFromDto(feePriorityToDto(p)), p);
      }
    });

    test('network maps by name', () {
      expect(networkToDto(AppNetwork.mainnet), NetworkDto.mainnet);
      expect(networkToDto(AppNetwork.testnet), NetworkDto.testnet);
      expect(networkToDto(AppNetwork.regtest), NetworkDto.regtest);
    });

    test('event kind maps every value', () {
      expect(eventKindFromDto(TransactionEventKindDto.created),
          TransactionEventKind.created);
      expect(eventKindFromDto(TransactionEventKindDto.statusChanged),
          TransactionEventKind.statusChanged);
      expect(eventKindFromDto(TransactionEventKindDto.confirmationsChanged),
          TransactionEventKind.confirmationsChanged);
    });
  });

  group('transactions', () {
    test('transactionFromDto maps every field', () {
      final dto = txDto(
        id: 'swap1',
        chain: ChainDto.liquid,
        direction: DirectionDto.swap,
        status: StatusDto.confirmed,
        amountSat: 1500,
        feeSat: 30,
        timestampMs: 1700000000000,
        confirmations: 1,
        assetId: 'usdt',
        fromAssetId: 'usdt',
        toAssetId: 'lbtc',
        sentAmountSat: 1500,
        receivedAmountSat: 900,
        source: SourceDto.lwk,
        label: 'lbl',
        address: 'addr',
        swapLockupTxId: 'lock',
        swapClaimTxId: 'claim',
      );
      final tx = transactionFromDto(dto);
      expect(tx.id, 'swap1');
      expect(tx.chain, ChainId.liquid);
      expect(tx.direction, TransactionDirection.swap);
      expect(tx.status, TransactionStatus.confirmed);
      expect(tx.amountSat, 1500);
      expect(tx.feeSat, 30);
      expect(tx.timestamp, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(tx.confirmations, 1);
      expect(tx.assetId, 'usdt');
      expect(tx.fromAssetId, 'usdt');
      expect(tx.toAssetId, 'lbtc');
      expect(tx.sentAmountSat, 1500);
      expect(tx.receivedAmountSat, 900);
      expect(tx.source, TransactionSource.lwk);
      expect(tx.label, 'lbl');
      expect(tx.address, 'addr');
      expect(tx.swapLockupTxId, 'lock');
      expect(tx.swapClaimTxId, 'claim');
    });

    test('transactionFromDto keeps nulls', () {
      final tx = transactionFromDto(txDto(id: 'a'));
      expect(tx.source, isNull);
      expect(tx.sentAmountSat, isNull);
      expect(tx.receivedAmountSat, isNull);
      expect(tx.assetId, isNull);
    });

    test('transactionToDto round-trips through transactionFromDto', () {
      final tx = Transaction(
        id: 'ext',
        chain: ChainId.bitcoin,
        direction: TransactionDirection.outgoing,
        status: TransactionStatus.pending,
        amountSat: 42000,
        feeSat: 210,
        timestamp: DateTime.fromMillisecondsSinceEpoch(1700000001000),
        address: 'bc1q',
        label: 'peg-in',
        source: TransactionSource.bdk,
        swapLockupTxId: 'lock',
      );
      final back = transactionFromDto(transactionToDto(tx));
      expect(back.toMap(), tx.toMap());
    });

    test('transactionEventFromDto maps previous fields', () {
      final e = transactionEventFromDto(TransactionEventDto(
        kind: TransactionEventKindDto.statusChanged,
        transaction: txDto(id: 't', status: StatusDto.confirmed),
        observedAtMs: BigInt.from(1700000002000),
        previousStatus: StatusDto.pending,
        previousConfirmations: 0,
      ));
      expect(e.kind, TransactionEventKind.statusChanged);
      expect(e.transaction.id, 't');
      expect(e.observedAt, DateTime.fromMillisecondsSinceEpoch(1700000002000));
      expect(e.previousStatus, TransactionStatus.pending);
      expect(e.previousConfirmations, 0);
    });
  });

  group('balances and send surface', () {
    test('balanceFromDto maps assets and snapshot time', () {
      final b = balanceFromDto(BalanceDto(
        assets: [
          AssetBalanceDto(
            chain: ChainDto.bitcoin,
            amountSat: BigInt.from(1000),
            precision: 8,
            ticker: 'BTC',
            pendingSat: BigInt.from(50),
          ),
        ],
        snapshotAtMs: BigInt.from(1700000003000),
      ));
      expect(b.assets, hasLength(1));
      expect(b.assets.single.chain, ChainId.bitcoin);
      expect(b.assets.single.amountSat, 1000);
      expect(b.assets.single.pendingSat, 50);
      expect(b.assets.single.ticker, 'BTC');
      expect(b.assets.single.assetId, isNull);
      expect(b.snapshotAt, DateTime.fromMillisecondsSinceEpoch(1700000003000));
    });

    test('feeEstimateFromDto maps every field', () {
      final f = feeEstimateFromDto(FeeEstimateDto(
        chain: ChainDto.liquid,
        priority: FeePriorityDto.high,
        absoluteFeeSat: BigInt.from(26),
        feeRateSatPerVbyte: 0.1,
        estimatedBlocks: 2,
      ));
      expect(f.chain, ChainId.liquid);
      expect(f.priority, FeePriority.high);
      expect(f.absoluteFeeSat, 26);
      expect(f.feeRateSatPerVByte, 0.1);
      expect(f.estimatedBlocks, 2);
    });

    test('receiveAddressFromDto maps every field', () {
      final r = receiveAddressFromDto(ReceiveAddressDto(
        chain: ChainDto.liquid,
        address: 'liquidnetwork:lq1?assetid=x',
        assetId: 'x',
        label: 'l',
        amountSat: BigInt.from(5),
      ));
      expect(r.chain, ChainId.liquid);
      expect(r.address, 'liquidnetwork:lq1?assetid=x');
      expect(r.assetId, 'x');
      expect(r.label, 'l');
      expect(r.amountSat, 5);
      expect(r.bolt11, isNull);
    });

    test('broadcastResultFromDto maps the transaction', () {
      final r = broadcastResultFromDto(BroadcastResultDto(
        chain: ChainDto.bitcoin,
        txId: 'tx',
        transaction: txDto(id: 'tx', chain: ChainDto.bitcoin),
        feePaidSat: BigInt.from(300),
      ));
      expect(r.chain, ChainId.bitcoin);
      expect(r.txId, 'tx');
      expect(r.transaction.id, 'tx');
      expect(r.feePaidSat, 300);
      expect(r.preimage, isNull);
    });

    test('liquidSendDraftFromDto and liquidUtxoFromDto keep BigInts', () {
      final d = liquidSendDraftFromDto(LiquidSendDraftDto(
        pset: 'p',
        destination: 'lq1',
        amountSat: BigInt.from(1000),
        feeSat: BigInt.from(26),
        feeRateSatPerKvb: 100,
        drain: true,
      ));
      expect(d.pset, 'p');
      expect(d.amountSat, BigInt.from(1000));
      expect(d.totalSat, BigInt.from(1026));
      expect(d.drain, isTrue);

      final u = liquidUtxoFromDto(LiquidUtxoDto(
        txid: 't',
        vout: 3,
        assetId: 'a',
        assetBlindingFactor: 'abf',
        valueSat: BigInt.from(77),
        valueBlindingFactor: 'vbf',
      ));
      expect(u.txid, 't');
      expect(u.vout, 3);
      expect(u.valueSat, BigInt.from(77));
      expect(u.assetBlindingFactor, 'abf');
      expect(u.valueBlindingFactor, 'vbf');
    });

    test('syncOutcomeFromDto converts the duration', () {
      final s = syncOutcomeFromDto(SyncOutcomeDto(
        chain: ChainDto.bitcoin,
        fetched: 7,
        changed: 2,
        durationMs: BigInt.from(1500),
      ));
      expect(s.chain, ChainId.bitcoin);
      expect(s.fetched, 7);
      expect(s.changed, 2);
      expect(s.duration, const Duration(milliseconds: 1500));
    });

    test('sendRequestToDto maps every field', () {
      const r = SendRequest(
        chain: ChainId.liquid,
        destination: 'lq1',
        amountSat: 1234,
        assetId: 'usdt',
        feePriority: FeePriority.low,
        label: 'l',
        subtractFeeFromAmount: true,
        feeRateOverrideSatPerVByte: 0.2,
        drain: true,
      );
      final dto = sendRequestToDto(r);
      expect(dto.destination, 'lq1');
      expect(dto.amountSat, BigInt.from(1234));
      expect(dto.assetId, 'usdt');
      expect(dto.feePriority, FeePriorityDto.low);
      expect(dto.label, 'l');
      expect(dto.subtractFeeFromAmount, isTrue);
      expect(dto.feeRateOverrideSatPerVbyte, 0.2);
      expect(dto.drain, isTrue);
    });

    test('sendRequestToDto clamps a negative amount to zero', () {
      const r = SendRequest(
          chain: ChainId.bitcoin, destination: 'bc1', amountSat: -5);
      expect(sendRequestToDto(r).amountSat, BigInt.zero);
    });
  });

  group('errors', () {
    test('coreErrorMessage strips the core variant prefix', () {
      const e = CoreError(
        kind: CoreErrorKind.service,
        message: 'wallet service failed on Bitcoin: bdk sync failed: boom',
      );
      expect(coreErrorMessage(e), 'bdk sync failed: boom');
    });

    test('service errors keep the core text', () {
      const e = CoreError(
        kind: CoreErrorKind.service,
        message: 'wallet service failed on Liquid: lwk signTx failed: bad',
      );
      final f = serviceFailureFromCoreError(e, ChainId.liquid,
          operation: 'lwk signAndBroadcastPset');
      expect(f.message, 'lwk signTx failed: bad');
      expect(f.chain, ChainId.liquid);
      expect(f.cause, e);
    });

    test('other kinds get the operation prefix', () {
      const e = CoreError(
          kind: CoreErrorKind.network, message: 'network: refused');
      final f = serviceFailureFrom(e, ChainId.bitcoin, operation: 'bdk sync');
      expect(f.message, 'bdk sync failed: network: refused');
    });

    test('a timeout maps to "<operation> timeout"', () {
      final f = serviceFailureFrom(TimeoutException('x'), ChainId.liquid,
          operation: 'lwk sync');
      expect(f.message, 'lwk sync timeout');
    });

    test('an unknown error maps to "<operation> failed: <error>"', () {
      final f = serviceFailureFrom(StateError('oops'), ChainId.bitcoin,
          operation: 'bdk getHeight');
      expect(f.message, 'bdk getHeight failed: Bad state: oops');
    });

    test('a ServiceFailure passes through', () {
      const sf = ServiceFailure('x', chain: ChainId.bitcoin);
      expect(serviceFailureFrom(sf, ChainId.bitcoin, operation: 'op'),
          same(sf));
    });
  });
}
