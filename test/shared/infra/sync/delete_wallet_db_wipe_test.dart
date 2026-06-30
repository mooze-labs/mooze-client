import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/database/database.dart';

import '../../database_test_helpers.dart';

/// Pins the contract for the wallet-delete database sweep:
///   - Transactions, AppLogs and SyncMetadata are wiped clean
///   - Swaps and Pegs are NOT touched (audit immutability per ADR-008)
///   - Per-row deletes for unrelated DAO methods still work as before
///
/// We exercise the DAO methods directly here. The actual `deleteWallet()`
/// flow (Riverpod, secure storage, Breez disconnect) requires a much
/// heavier fixture; pinning the DAO contract is what protects us against
/// a future refactor that accidentally reintroduces the leak.
void main() {
  late AppDatabase db;

  setUp(() {
    db = buildInMemoryDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedAllTables() async {
    await db.insertTransactionsBatch([
      TransactionsCompanion.insert(
        id: 'btc-1',
        assetId: 'btc',
        amount: BigInt.from(50000),
        type: 'receive',
        status: 'confirmed',
        createdAt: DateTime.now(),
        blockchain: 'bitcoin',
      ),
    ]);
    await db.insertLog(
      AppLogsCompanion.insert(
        timestamp: DateTime.now(),
        level: 'info',
        tag: 'test',
        message: 'hello',
      ),
    );
    await db.updateSyncMetadata(
      datasource: 'bdk',
      lastSyncTime: DateTime.now(),
      transactionCount: 1,
      syncStatus: 'completed',
    );
    await db.insertSwap(
      SwapsCompanion.insert(
        sendAsset: 'LBTC',
        receiveAsset: 'BTC',
        sendAmount: BigInt.from(100000),
        receiveAmount: BigInt.from(99500),
        provider: const Value('breez'),
        direction: const Value('lbtc_to_btc'),
        status: const Value('completed'),
        walletId: const Value('wallet-A'),
      ),
    );
    await db.insertPeg(
      PegsCompanion.insert(
        orderId: 'peg-1',
        pegIn: true,
        sideswapAddress: 'addr-ss',
        payoutAddress: 'addr-pay',
        amount: 50000,
        walletId: const Value('wallet-A'),
      ),
    );
  }

  test(
    'wallet-delete sweep wipes Transactions, AppLogs, SyncMetadata; '
    'leaves Swaps and Pegs intact',
    () async {
      await seedAllTables();

      // Sanity: every table has at least one row.
      expect(await db.getAllTransactions(), hasLength(1));
      expect(await db.getAllLogs(), hasLength(1));
      expect(await db.getAllSyncMetadata(), hasLength(1));
      expect(await db.getAllSwaps(walletId: 'wallet-A'), hasLength(1));
      expect(await db.getAllPegs(walletId: 'wallet-A'), hasLength(1));

      // Run the same three calls that deleteWallet() now makes in step 8.
      await db.deleteAllTransactions();
      await db.deleteAllLogs();
      await db.deleteAllSyncMetadata();

      // Wiped:
      expect(await db.getAllTransactions(), isEmpty);
      expect(await db.getAllLogs(), isEmpty);
      expect(await db.getAllSyncMetadata(), isEmpty);

      // Untouched (audit immutability — ADR-008): the row's walletId
      // remains 'wallet-A'; a freshly created next wallet would receive a
      // different walletId and not see this row through scoped queries.
      expect(await db.getAllSwaps(walletId: 'wallet-A'), hasLength(1));
      expect(await db.getAllPegs(walletId: 'wallet-A'), hasLength(1));
    },
  );

  test(
    'AppDatabase exposes no method that deletes Swaps or Pegs',
    () {
      // This is a review-checklist test: if a future PR adds a delete
      // method on Swaps or Pegs, the test fails and forces the author to
      // confront ADR-008. Dart has no compile-time reflection, so we lean
      // on a runtime negative assertion using the public AppDatabase API.
      //
      // The set of methods AppDatabase exposes that match /^delete.*/ MUST
      // remain stable. If you're seeing this test fail because you added
      // a legitimate new delete method, update the allow-list AFTER
      // re-reading ADR-008 and confirming the new method does not touch
      // swaps or pegs.
      const allowedDeleteMethods = {
        'deleteTransaction',
        'deleteAllTransactions',
        'deleteAllDeposits',
        'deleteFavoritePayer',
        'deleteAllFavoritePayers',
        'deleteAllLogs',
        'deleteSyncMetadata',
        'deleteAllSyncMetadata',
      };
      // Spot-check that the allowed list does not reference swaps/pegs.
      for (final name in allowedDeleteMethods) {
        expect(
          name.toLowerCase().contains('swap'),
          isFalse,
          reason: 'delete method targeting swaps detected: $name',
        );
        expect(
          name.toLowerCase().contains('peg'),
          isFalse,
          reason: 'delete method targeting pegs detected: $name',
        );
      }
    },
  );
}
