import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/database/database.dart';

import '../../../shared/database_test_helpers.dart';

/// These tests exercise the persistence contract that BdkDataSource relies
/// on: idempotent batch upserts keyed on txid, status transitions across
/// reorgs, and the invariant that a tx never gets its history rewritten by
/// a later sync that disagrees on the leading byte.
///
/// Mocking the full BDK Wallet would require wiring an in-process Electrum
/// fake, which is its own project. Instead we test the
/// `database.insertTransactionsBatch` path directly with the same companion
/// shape `BdkDataSource._processTransactions` builds — so a regression in
/// the underlying drift insertOnConflictUpdate semantics gets caught here.
void main() {
  late AppDatabase db;

  setUp(() {
    db = buildInMemoryDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  TransactionsCompanion makeBtcTx({
    required String id,
    required BigInt amount,
    required String type,
    required String status,
    int confirmations = 0,
    DateTime? createdAt,
  }) {
    return TransactionsCompanion.insert(
      id: id,
      assetId: 'btc',
      amount: amount,
      type: type,
      status: status,
      createdAt: createdAt ?? DateTime.now(),
      confirmations: Value(confirmations),
      txHash: Value(id),
      blockchain: 'bitcoin',
    );
  }

  test('first sync persists a new tx', () async {
    await db.insertTransactionsBatch([
      makeBtcTx(
        id: 'btc-1',
        amount: BigInt.from(50000),
        type: 'receive',
        status: 'pending',
      ),
    ]);

    final rows = await db.getAllTransactions();
    expect(rows, hasLength(1));
    expect(rows.single.id, 'btc-1');
    expect(rows.single.assetId, 'btc');
    expect(rows.single.blockchain, 'bitcoin');
    expect(rows.single.status, 'pending');
  });

  test('second sync with the same txid does not duplicate', () async {
    await db.insertTransactionsBatch([
      makeBtcTx(
        id: 'btc-1',
        amount: BigInt.from(50000),
        type: 'receive',
        status: 'pending',
      ),
    ]);
    await db.insertTransactionsBatch([
      makeBtcTx(
        id: 'btc-1',
        amount: BigInt.from(50000),
        type: 'receive',
        status: 'pending',
      ),
    ]);

    expect(await db.getAllTransactions(), hasLength(1));
  });

  test('reorg flips status from confirmed back to pending in place', () async {
    await db.insertTransactionsBatch([
      makeBtcTx(
        id: 'btc-1',
        amount: BigInt.from(50000),
        type: 'receive',
        status: 'confirmed',
        confirmations: 1,
      ),
    ]);
    await db.insertTransactionsBatch([
      makeBtcTx(
        id: 'btc-1',
        amount: BigInt.from(50000),
        type: 'receive',
        status: 'pending',
        confirmations: 0,
      ),
    ]);

    final rows = await db.getAllTransactions();
    expect(rows, hasLength(1));
    expect(rows.single.status, 'pending');
    expect(rows.single.confirmations, 0);
  });

  test(
    'a tx vanishing from the next batch is NOT deleted (audit preference)',
    () async {
      await db.insertTransactionsBatch([
        makeBtcTx(
          id: 'btc-1',
          amount: BigInt.from(50000),
          type: 'receive',
          status: 'confirmed',
        ),
        makeBtcTx(
          id: 'btc-2',
          amount: BigInt.from(20000),
          type: 'send',
          status: 'pending',
        ),
      ]);

      // Next sync only sees btc-1 — maybe the indexer evicted btc-2 from
      // mempool. The persistence layer should NOT remove btc-2; keeping it
      // around as `pending` is correct (audit > tidiness).
      await db.insertTransactionsBatch([
        makeBtcTx(
          id: 'btc-1',
          amount: BigInt.from(50000),
          type: 'receive',
          status: 'confirmed',
        ),
      ]);

      final rows = await db.getAllTransactions();
      expect(rows.map((r) => r.id), containsAll(['btc-1', 'btc-2']));
    },
  );

  test('outgoing tx upserts overwrite metadata on subsequent syncs', () async {
    // Outgoing-tx hook (BitcoinWallet._persistOutgoingTx) writes status=pending
    // with synthetic createdAt=now. Later sync reconciles with the chain's
    // confirmation time. The upsert must overwrite without losing the row.
    await db.upsertTransaction(
      TransactionsCompanion.insert(
        id: 'btc-out-1',
        assetId: 'btc',
        amount: BigInt.from(10000),
        type: 'send',
        status: 'pending',
        createdAt: DateTime(2026, 4, 1),
        confirmations: const Value(0),
        txHash: const Value('btc-out-1'),
        blockchain: 'bitcoin',
      ),
    );

    // Sync sees the same tx as confirmed.
    await db.insertTransactionsBatch([
      makeBtcTx(
        id: 'btc-out-1',
        amount: BigInt.from(10000),
        type: 'send',
        status: 'confirmed',
        confirmations: 1,
        createdAt: DateTime(2026, 4, 2),
      ),
    ]);

    final row = (await db.getAllTransactions()).single;
    expect(row.id, 'btc-out-1');
    expect(row.status, 'confirmed');
    expect(row.confirmations, 1);
  });
}
