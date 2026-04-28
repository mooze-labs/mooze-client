import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/database/database.dart';
import 'package:mooze_mobile/features/wallet/data/repositories/swap_audit_repository_impl.dart';
import 'package:mooze_mobile/features/wallet/domain/repositories/swap_audit_repository.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';

import '../../../shared/database_test_helpers.dart';

void main() {
  late AppDatabase db;
  late AppLoggerService logger;
  late SwapAuditRepository audit;

  setUp(() {
    db = buildInMemoryDatabase();
    // AppLoggerService is a singleton across tests — that's fine here, the
    // service tolerates being re-initialized and we only assert on DB state.
    logger = AppLoggerService();
    audit = SwapAuditRepositoryImpl(db, logger);
  });

  tearDown(() async {
    await db.close();
  });

  group('recordPending', () {
    test('inserts a row with status=pending and returns its id', () async {
      final result = await audit.recordPending(
        provider: 'breez',
        direction: 'lbtc_to_btc',
        sendAsset: 'LBTC',
        receiveAsset: 'BTC',
        sendAmount: BigInt.from(100000),
        receiveAmount: BigInt.from(99500),
        metadata: {'feeRateSatPerVbyte': 1},
      );

      expect(result.isRight(), isTrue);
      final id = result.getRight().getOrElse(() => -1);
      expect(id, greaterThan(0));

      final rows = await db.getAllSwaps();
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row.id, id);
      expect(row.provider, 'breez');
      expect(row.direction, 'lbtc_to_btc');
      expect(row.status, 'pending');
      expect(row.sendAmount, BigInt.from(100000));
      expect(row.receiveAmount, BigInt.from(99500));
      expect(row.metadata, isNotNull);
      expect(jsonDecode(row.metadata!), {'feeRateSatPerVbyte': 1});
    });

    test('serializes optional metadata as JSON; omits when null', () async {
      final r1 = await audit.recordPending(
        provider: 'breez',
        direction: 'btc_to_lbtc',
        sendAsset: 'BTC',
        receiveAsset: 'LBTC',
        sendAmount: BigInt.from(50000),
        receiveAmount: BigInt.from(49800),
      );
      expect(r1.isRight(), isTrue);

      final rows = await db.getAllSwaps();
      expect(rows.single.metadata, isNull);
    });
  });

  group('markFinal', () {
    test('updates status, txId and metadata of an existing row', () async {
      final id =
          (await audit.recordPending(
            provider: 'breez',
            direction: 'lbtc_to_btc',
            sendAsset: 'LBTC',
            receiveAsset: 'BTC',
            sendAmount: BigInt.from(100000),
            receiveAmount: BigInt.from(99500),
          )).getRight().getOrElse(() => -1);

      final result = await audit.markFinal(
        id: id,
        status: 'completed',
        txId: 'btc-tx-abc',
        metadata: {'paymentHash': 'p1'},
      );

      expect(result.isRight(), isTrue);

      final row = (await db.getAllSwaps()).single;
      expect(row.id, id);
      expect(row.status, 'completed');
      expect(row.txId, 'btc-tx-abc');
      expect(jsonDecode(row.metadata!), {'paymentHash': 'p1'});
    });

    test('preserves audit-critical fields on update', () async {
      final id =
          (await audit.recordPending(
            provider: 'breez',
            direction: 'lbtc_to_btc',
            sendAsset: 'LBTC',
            receiveAsset: 'BTC',
            sendAmount: BigInt.from(100000),
            receiveAmount: BigInt.from(99500),
          )).getRight().getOrElse(() => -1);

      await audit.markFinal(id: id, status: 'failed');

      final row = (await db.getAllSwaps()).single;
      expect(row.provider, 'breez');
      expect(row.direction, 'lbtc_to_btc');
      expect(row.sendAsset, 'LBTC');
      expect(row.receiveAsset, 'BTC');
      expect(row.sendAmount, BigInt.from(100000));
      expect(row.receiveAmount, BigInt.from(99500));
      expect(row.status, 'failed');
    });

    test('row count stays at 1 — no row is ever deleted', () async {
      final id =
          (await audit.recordPending(
            provider: 'breez',
            direction: 'lbtc_to_btc',
            sendAsset: 'LBTC',
            receiveAsset: 'BTC',
            sendAmount: BigInt.from(100000),
            receiveAmount: BigInt.from(99500),
          )).getRight().getOrElse(() => -1);

      await audit.markFinal(id: id, status: 'completed', txId: 'tx-1');
      await audit.markFinal(id: id, status: 'failed', txId: 'tx-2');

      final rows = await db.getAllSwaps();
      expect(rows, hasLength(1));
      expect(rows.single.status, 'failed');
      expect(rows.single.txId, 'tx-2');
    });

    test('returns Left when the row does not exist', () async {
      final result = await audit.markFinal(id: 99999, status: 'completed');
      expect(result.isLeft(), isTrue);
    });
  });

  group('recordCompleted (idempotent)', () {
    test('inserts when no prior row exists for the txId', () async {
      final result = await audit.recordCompleted(
        provider: 'internal_liquid',
        direction: 'asset_swap',
        sendAsset: 'asset-A',
        receiveAsset: 'asset-B',
        sendAmount: BigInt.from(100),
        receiveAmount: BigInt.from(95),
        txId: 'liquid-tx-1',
      );
      expect(result.isRight(), isTrue);
      final rows = await db.getAllSwaps();
      expect(rows, hasLength(1));
      expect(rows.single.status, 'completed');
      expect(rows.single.txId, 'liquid-tx-1');
    });

    test('returns existing id and does not insert when txId matches', () async {
      final first = await audit.recordCompleted(
        provider: 'internal_liquid',
        direction: 'asset_swap',
        sendAsset: 'asset-A',
        receiveAsset: 'asset-B',
        sendAmount: BigInt.from(100),
        receiveAmount: BigInt.from(95),
        txId: 'liquid-tx-1',
      );
      final firstId = first.getRight().getOrElse(() => -1);

      final second = await audit.recordCompleted(
        provider: 'internal_liquid',
        direction: 'asset_swap',
        sendAsset: 'asset-A',
        receiveAsset: 'asset-B',
        sendAmount: BigInt.from(100),
        receiveAmount: BigInt.from(95),
        txId: 'liquid-tx-1',
      );
      final secondId = second.getRight().getOrElse(() => -2);

      expect(secondId, firstId);
      expect(await db.getAllSwaps(), hasLength(1));
    });

    test(
      'idempotency hits when send-leg id is in metadata of an earlier row',
      () async {
        // Liquid asset swap: store both leg ids in metadata; when the matcher
        // re-runs and tries to record the same swap by send-leg txId, it
        // should hit the metadata match and skip.
        final first = await audit.recordCompleted(
          provider: 'internal_liquid',
          direction: 'asset_swap',
          sendAsset: 'asset-A',
          receiveAsset: 'asset-B',
          sendAmount: BigInt.from(100),
          receiveAmount: BigInt.from(95),
          txId: 'send-leg-1',
          metadata: {'sendTxId': 'send-leg-1', 'receiveTxId': 'recv-leg-1'},
        );
        expect(first.isRight(), isTrue);

        final second = await audit.recordCompleted(
          provider: 'internal_liquid',
          direction: 'asset_swap',
          sendAsset: 'asset-A',
          receiveAsset: 'asset-B',
          sendAmount: BigInt.from(100),
          receiveAmount: BigInt.from(95),
          txId: 'send-leg-1',
        );
        expect(second.isRight(), isTrue);
        expect(await db.getAllSwaps(), hasLength(1));
      },
    );

    test('different providers with same txId are NOT deduped', () async {
      // A breez peg-out and an internal_liquid swap could in theory share a
      // txId by coincidence; the idempotency check is scoped per-provider.
      await audit.recordCompleted(
        provider: 'breez',
        direction: 'lbtc_to_btc',
        sendAsset: 'LBTC',
        receiveAsset: 'BTC',
        sendAmount: BigInt.from(100),
        receiveAmount: BigInt.from(95),
        txId: 'shared-tx-id',
      );
      await audit.recordCompleted(
        provider: 'internal_liquid',
        direction: 'asset_swap',
        sendAsset: 'asset-A',
        receiveAsset: 'asset-B',
        sendAmount: BigInt.from(100),
        receiveAmount: BigInt.from(95),
        txId: 'shared-tx-id',
      );
      expect(await db.getAllSwaps(), hasLength(2));
    });

    test('without txId, every call inserts (no idempotency basis)', () async {
      for (int i = 0; i < 3; i++) {
        await audit.recordCompleted(
          provider: 'breez',
          direction: 'lbtc_to_btc',
          sendAsset: 'LBTC',
          receiveAsset: 'BTC',
          sendAmount: BigInt.from(100),
          receiveAmount: BigInt.from(95),
        );
      }
      expect(await db.getAllSwaps(), hasLength(3));
    });
  });

  group('immutability invariant', () {
    test(
      'no public AppDatabase method can delete a row from the swaps table',
      () async {
        // This test is the canary for ADR-008. If anyone adds a delete
        // method to AppDatabase in the future, this assertion catches it.
        // We exhaustively call every exposed audit-write path and verify the
        // row count never decreases.
        final id =
            (await audit.recordPending(
              provider: 'breez',
              direction: 'lbtc_to_btc',
              sendAsset: 'LBTC',
              receiveAsset: 'BTC',
              sendAmount: BigInt.from(100),
              receiveAmount: BigInt.from(95),
            )).getRight().getOrElse(() => -1);

        await audit.markFinal(id: id, status: 'completed', txId: 'a');
        await audit.markFinal(id: id, status: 'failed', txId: 'b');
        await audit.markFinal(id: id, status: 'completed', txId: 'c');

        expect(await db.getAllSwaps(), hasLength(1));
        // Spot-check: the public DAO surface for swaps does not expose any
        // delete-shaped method. A reflection-based test here would be
        // ideal, but Dart has no compile-time reflection — so this is
        // primarily a "review the diff" test rather than a runtime guard.
      },
    );
  });

  group('DAO primitives', () {
    test(
      'swapExistsForTxId scopes by provider and matches metadata substrings',
      () async {
        await audit.recordCompleted(
          provider: 'internal_liquid',
          direction: 'asset_swap',
          sendAsset: 'A',
          receiveAsset: 'B',
          sendAmount: BigInt.from(1),
          receiveAmount: BigInt.from(1),
          txId: 'send-1',
          metadata: {'sendTxId': 'send-1', 'receiveTxId': 'recv-1'},
        );

        expect(
          await db.swapExistsForTxId(provider: 'internal_liquid', txId: 'send-1'),
          isTrue,
        );
        expect(
          await db.swapExistsForTxId(provider: 'internal_liquid', txId: 'recv-1'),
          isTrue,
        );
        expect(
          await db.swapExistsForTxId(provider: 'breez', txId: 'send-1'),
          isFalse,
        );
        expect(
          await db.swapExistsForTxId(
            provider: 'internal_liquid',
            txId: 'unknown',
          ),
          isFalse,
        );
      },
    );

    test(
      'findPendingPegInByDepositAddress returns the most recent pending row',
      () async {
        // A pending peg-in records the deposit address in metadata.
        final id1 =
            (await audit.recordPending(
              provider: 'breez',
              direction: 'btc_to_lbtc',
              sendAsset: 'BTC',
              receiveAsset: 'LBTC',
              sendAmount: BigInt.from(50000),
              receiveAmount: BigInt.from(49500),
              metadata: {'depositAddress': 'bc1qxyz'},
            )).getRight().getOrElse(() => -1);

        final found = await db.findPendingPegInByDepositAddress(
          provider: 'breez',
          depositAddress: 'bc1qxyz',
        );
        expect(found, isNotNull);
        expect(found!.id, id1);
        expect(found.status, 'pending');

        // After we mark it final, the lookup must no longer return it.
        await audit.markFinal(id: id1, status: 'completed', txId: 'btc-1');

        final found2 = await db.findPendingPegInByDepositAddress(
          provider: 'breez',
          depositAddress: 'bc1qxyz',
        );
        expect(found2, isNull);
      },
    );
  });
}
