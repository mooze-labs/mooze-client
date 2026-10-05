// drift exports query-builder `isNull`/`isNotNull` that shadow matcher's.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:mooze_mobile/database/database.dart';

/// Covers the v13 → v14 `Pegs` migration and the lifecycle DAO surface it
/// enables.
///
/// The migration is the risky half: pre-v14 rows were written once, after the
/// fact, as pure history. Adding mutable lifecycle columns must not disturb
/// them, and must not weaken the append-only invariant (`status` is updated
/// in place; nothing is ever deleted).
void main() {
  group('v13 → v14 migration', () {
    late QueryExecutor executor;
    late AppDatabase db;

    setUp(() async {
      // Seed the pre-v14 `pegs` shape on a raw sqlite handle and stamp
      // user_version = 13. Going through AppDatabase here would not work:
      // constructing it runs `onCreate`, which builds every table at v14 and
      // never exercises the upgrade path we are trying to test.
      final raw = sqlite3.openInMemory();
      raw.execute('''
        CREATE TABLE pegs (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          order_id TEXT NOT NULL,
          peg_in INTEGER NOT NULL CHECK (peg_in IN (0, 1)),
          sideswap_address TEXT NOT NULL,
          payout_address TEXT NOT NULL,
          amount INTEGER NOT NULL,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          wallet_id TEXT NOT NULL DEFAULT 'unknown'
        )
      ''');
      raw.execute(
        "INSERT INTO pegs (order_id, peg_in, sideswap_address, payout_address, "
        "amount, created_at, wallet_id) "
        "VALUES ('legacy-order', 1, 'ss-addr', 'pay-addr', 42000, "
        "strftime('%s','now'), 'wallet-A')",
      );
      raw.execute('PRAGMA user_version = 13');

      executor = NativeDatabase.opened(raw);
      db = AppDatabase(executor);
    });

    tearDown(() async => db.close());

    test('adds the lifecycle columns and preserves the legacy row', () async {
      final pegs = await db.getAllPegs(walletId: 'wallet-A');

      expect(pegs, hasLength(1));
      final legacy = pegs.single;
      expect(legacy.orderId, 'legacy-order');
      expect(legacy.amount, 42000);
      expect(legacy.sideswapAddress, 'ss-addr');
      expect(legacy.payoutAddress, 'pay-addr');
      expect(legacy.pegIn, isTrue);

      // Historical rows describe finished operations, so they must not be
      // resurrected as pending by the migration's defaults.
      expect(legacy.status, pegStatusCompleted);
      expect(legacy.provider, 'sideswap');
      expect(legacy.fundingTxId, isNull);
      expect(legacy.payoutTxId, isNull);
      expect(legacy.updatedAt, isNull);
    });

    test('a migrated row is not picked up as an active peg', () async {
      // Boot recovery reads getActivePegs. A legacy row surfacing there would
      // make the tracker poll a years-old order forever.
      final active = await db.getActivePegs(walletId: 'wallet-A');
      expect(active, isEmpty);
    });

    test('schemaVersion is 14', () {
      expect(db.schemaVersion, 14);
    });
  });

  group('peg lifecycle DAO', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() async => db.close());

    Future<void> insertPending(String orderId, {String wallet = 'w1'}) =>
        db.insertPeg(
          PegsCompanion.insert(
            orderId: orderId,
            pegIn: false,
            sideswapAddress: 'lq1-deposit',
            payoutAddress: 'bc1-payout',
            amount: 100000,
            walletId: Value(wallet),
            status: const Value(pegStatusPending),
          ),
        );

    test('getActivePegs returns only pending rows, oldest first', () async {
      await insertPending('order-1');
      await insertPending('order-2');
      await db.updatePegProgress(
        orderId: 'order-1',
        walletId: 'w1',
        status: pegStatusCompleted,
        updatedAt: DateTime.now(),
      );

      final active = await db.getActivePegs(walletId: 'w1');
      expect(active.map((p) => p.orderId), ['order-2']);
    });

    test('getActivePegs is wallet-scoped', () async {
      await insertPending('order-a', wallet: 'w1');
      await insertPending('order-b', wallet: 'w2');

      expect((await db.getActivePegs(walletId: 'w1')).map((p) => p.orderId), [
        'order-a',
      ]);
      expect((await db.getActivePegs(walletId: 'w2')).map((p) => p.orderId), [
        'order-b',
      ]);
    });

    test('findPegByOrderId enables idempotent order creation', () async {
      // The reconciliation path after a create timeout: if the order turns
      // out to exist, we must find the row instead of inserting a second one.
      await insertPending('order-x');

      final found = await db.findPegByOrderId(
        orderId: 'order-x',
        walletId: 'w1',
      );
      expect(found, isNotNull);
      expect(found!.orderId, 'order-x');

      expect(
        await db.findPegByOrderId(orderId: 'order-x', walletId: 'other'),
        isNull,
        reason: 'lookup must stay wallet-scoped',
      );
      expect(
        await db.findPegByOrderId(orderId: 'nope', walletId: 'w1'),
        isNull,
      );
    });

    test('updatePegProgress writes only the fields it is given', () async {
      await insertPending('order-p');

      await db.updatePegProgress(
        orderId: 'order-p',
        walletId: 'w1',
        fundingTxId: 'lwk-txid',
        updatedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );
      var row = await db.findPegByOrderId(orderId: 'order-p', walletId: 'w1');
      expect(row!.fundingTxId, 'lwk-txid');
      expect(row.status, pegStatusPending, reason: 'status left untouched');
      expect(row.payoutTxId, isNull);

      await db.updatePegProgress(
        orderId: 'order-p',
        walletId: 'w1',
        status: pegStatusCompleted,
        payoutTxId: 'btc-txid',
        updatedAt: DateTime.now(),
      );
      row = await db.findPegByOrderId(orderId: 'order-p', walletId: 'w1');
      expect(row!.status, pegStatusCompleted);
      expect(row.payoutTxId, 'btc-txid');
      expect(row.fundingTxId, 'lwk-txid', reason: 'earlier write preserved');
    });

    test('updatePegProgress encodes metadata as JSON', () async {
      await insertPending('order-m');
      await db.updatePegProgress(
        orderId: 'order-m',
        walletId: 'w1',
        metadata: {'depositAddress': 'lq1-deposit', 'feeSat': 26},
        updatedAt: DateTime.now(),
      );

      final row = await db.findPegByOrderId(orderId: 'order-m', walletId: 'w1');
      expect(row!.metadata, contains('lq1-deposit'));
      expect(row.metadata, contains('26'));
    });

    test('updating an unknown order touches nothing', () async {
      final touched = await db.updatePegProgress(
        orderId: 'ghost',
        walletId: 'w1',
        status: pegStatusFailed,
        updatedAt: DateTime.now(),
      );
      expect(touched, 0);
    });

    test(
      'a terminal peg keeps its row — status changes, nothing is deleted',
      () async {
        // The append-only invariant. A failed peg must remain queryable for
        // support; only its status moves.
        await insertPending('order-f');
        await db.updatePegProgress(
          orderId: 'order-f',
          walletId: 'w1',
          status: pegStatusFailed,
          errorMessage: 'broadcast rejected',
          updatedAt: DateTime.now(),
        );

        final all = await db.getAllPegs(walletId: 'w1');
        expect(all, hasLength(1));
        expect(all.single.status, pegStatusFailed);
        expect(all.single.errorMessage, 'broadcast rejected');
        expect(await db.getActivePegs(walletId: 'w1'), isEmpty);
      },
    );
  });
}
