import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

class Swaps extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sendAsset => text().withLength(min: 64, max: 64)();
  TextColumn get receiveAsset => text().withLength(min: 64, max: 64)();
  IntColumn get sendAmount => integer()();
  IntColumn get receiveAmount => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Pegs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get orderId => text()();
  BoolColumn get pegIn => boolean()();
  TextColumn get sideswapAddress => text()();
  TextColumn get payoutAddress => text()();
  IntColumn get amount => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Deposits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get depositId => text()();
  TextColumn get assetId => text()();
  IntColumn get amountInCents => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get status => text()();
  late final assetAmount = int64().nullable()();
  TextColumn get blockchainTxid => text().nullable()();
  TextColumn get pixKey => text()();
}

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  RealColumn get price => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Tabela para armazenar logs do aplicativo
class AppLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get level => text().withLength(min: 1, max: 20)();
  TextColumn get tag => text().withLength(min: 1, max: 100)();
  TextColumn get message => text()();
  TextColumn get error => text().nullable()();
  TextColumn get stackTrace => text().nullable()();
}

class SyncMetadata extends Table {
  TextColumn get datasource => text()();
  DateTimeColumn get lastSyncTime => dateTime()();
  IntColumn get transactionCount => integer()();
  TextColumn get syncStatus => text()();

  @override
  Set<Column> get primaryKey => {datasource};
}

class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get assetId => text()();
  Int64Column get amount => int64()();
  TextColumn get type => text()(); // "send" | "receive" | "swap"
  TextColumn get status => text()(); // "pending" | "confirmed" | "failed"
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get confirmations => integer().withDefault(const Constant(0))();
  TextColumn get txHash => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get metadata => text().nullable()(); // JSON
  TextColumn get blockchain => text()(); // "bitcoin" | "liquid" | "lightning"

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Swaps,
    Pegs,
    Deposits,
    Products,
    AppLogs,
    SyncMetadata,
    Transactions,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 8;

  // Get all swaps
  Future<List<Swap>> getAllSwaps() => select(swaps).get();

  // Get all pegs
  Future<List<Peg>> getAllPegs() => select(pegs).get();

  // Log operations
  Future<int> insertLog(AppLogsCompanion log) => into(appLogs).insert(log);

  Future<List<AppLog>> getAllLogs() => select(appLogs).get();

  Future<List<AppLog>> getLogsByLevel(String level) =>
      (select(appLogs)..where((log) => log.level.equals(level))).get();

  Future<List<AppLog>> getLogsByTimeRange(DateTime start, DateTime end) =>
      (select(appLogs)
            ..where((log) => log.timestamp.isBiggerOrEqualValue(start))
            ..where((log) => log.timestamp.isSmallerOrEqualValue(end)))
          .get();

  Future<int> deleteOldLogs(DateTime cutoffDate) =>
      (delete(appLogs)
        ..where((log) => log.timestamp.isSmallerThanValue(cutoffDate))).go();

  Future<int> deleteAllLogs() => delete(appLogs).go();

  Future<int> getLogsCount() async {
    final countExp = appLogs.id.count();
    final query = selectOnly(appLogs)..addColumns([countExp]);
    final result = await query.getSingleOrNull();
    return result?.read(countExp) ?? 0;
  }

  // ==================== Transaction Operations ====================

  /// Get all transactions
  Future<List<Transaction>> getAllTransactions() => select(transactions).get();

  /// Get transactions by blockchain
  Future<List<Transaction>> getTransactionsByBlockchain(String blockchain) =>
      (select(transactions)
        ..where((t) => t.blockchain.equals(blockchain))).get();

  /// Get transactions by asset
  Future<List<Transaction>> getTransactionsByAsset(String assetId) =>
      (select(transactions)..where((t) => t.assetId.equals(assetId))).get();

  /// Get single transaction by ID
  Future<Transaction?> getTransactionById(String id) =>
      (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Insert or update a single transaction
  Future<int> upsertTransaction(TransactionsCompanion transaction) =>
      into(transactions).insertOnConflictUpdate(transaction);

  /// Batch insert transactions (optimized for bulk operations)
  Future<void> insertTransactionsBatch(List<TransactionsCompanion> txs) async {
    await batch((batch) {
      for (final tx in txs) {
        batch.insert(transactions, tx, mode: InsertMode.insertOrReplace);
      }
    });
  }

  /// Check if a transaction has changed (for smart updates)
  Future<bool> hasTransactionChanged(
    String txId,
    String status,
    int confirmations,
    BigInt amount,
  ) async {
    final existing =
        await (select(transactions)
          ..where((t) => t.id.equals(txId))).getSingleOrNull();

    if (existing == null) return true;

    return existing.status != status ||
        existing.confirmations != confirmations ||
        existing.amount != amount;
  }

  /// Delete transaction by ID
  Future<int> deleteTransaction(String id) =>
      (delete(transactions)..where((t) => t.id.equals(id))).go();

  /// Delete all transactions
  Future<int> deleteAllTransactions() => delete(transactions).go();

  /// Get transaction count
  Future<int> getTransactionCount() async {
    final countExp = transactions.id.count();
    final query = selectOnly(transactions)..addColumns([countExp]);
    final result = await query.getSingleOrNull();
    return result?.read(countExp) ?? 0;
  }

  // ==================== Sync Metadata Operations ====================

  /// Get sync metadata for a datasource
  Future<SyncMetadataData?> getLastSync(String datasource) async {
    return await (select(syncMetadata)
      ..where((t) => t.datasource.equals(datasource))).getSingleOrNull();
  }

  /// Update sync metadata
  Future<void> updateSyncMetadata({
    required String datasource,
    required DateTime lastSyncTime,
    required int transactionCount,
    required String syncStatus,
  }) async {
    await into(syncMetadata).insertOnConflictUpdate(
      SyncMetadataCompanion.insert(
        datasource: datasource,
        lastSyncTime: lastSyncTime,
        transactionCount: transactionCount,
        syncStatus: syncStatus,
      ),
    );
  }

  /// Get all sync metadata
  Future<List<SyncMetadataData>> getAllSyncMetadata() =>
      select(syncMetadata).get();

  /// Delete sync metadata for a datasource
  Future<int> deleteSyncMetadata(String datasource) =>
      (delete(syncMetadata)
        ..where((t) => t.datasource.equals(datasource))).go();

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) => m.createAll(),
      onUpgrade: (m, from, to) async {
        if (from <= 1 && to >= 2) {
          await m.createTable(deposits);
        }
        if (from <= 2 && to >= 3) {
          try {
            await m.addColumn(deposits, deposits.blockchainTxid);
          } catch (e) {
            // Column already exists, ignore the error
          }
        }
        if (from <= 3 && to >= 4) {
          await m.alterTable(
            TableMigration(
              deposits,
              columnTransformer: {deposits.status: Constant('pending')},
              newColumns: [deposits.status],
            ),
          );
        }
        if (from <= 4 && to >= 5) {
          await m.alterTable(
            TableMigration(
              deposits,
              columnTransformer: {deposits.pixKey: Constant("N/A")},
              newColumns: [deposits.pixKey],
            ),
          );
        }
        if (from <= 5 && to >= 6) {
          await m.createTable(products);
        }
        if (from <= 6 && to >= 7) {
          await m.createTable(appLogs);
        }
        if (from <= 7 && to >= 8) {
          await m.createTable(syncMetadata);
          await m.createTable(transactions);
        }
      },
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'mooze_db',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
