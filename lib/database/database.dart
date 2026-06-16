import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

/// Immutable audit log of every swap the user has executed.
///
/// IMMUTABILITY INVARIANT (enforced by DAO surface, see [AppDatabase]):
/// no delete or update method is exposed for this table. Once a swap row is
/// inserted, it cannot be removed by user action. This is a hard requirement
/// for support and audit reconstruction — see DECISIONS.md ADR for swap
/// persistence.
///
/// Columns:
///  - sendAsset / receiveAsset: provider-defined identifiers. For Liquid
///    assets these are the 64-char asset hash; for BTC peg flows we accept
///    short symbolic ids ("BTC", "LBTC") so the schema covers every provider
///    without coupling to Liquid asset hashing.
///  - provider: "breez" | "sideswap" | "internal_liquid" — names the source
///    that produced the swap so the export and support tooling can group.
///  - status: "pending" | "completed" | "failed" — final state of the swap.
///    Pending rows are upserted (by id) once the outcome is known; the row
///    itself is never deleted.
///  - direction: free-form short label ("lbtc_to_btc", "btc_to_lbtc",
///    "asset_swap"); kept as text so future providers can introduce new
///    directions without a migration.
///  - txId: optional on-chain or off-chain reference (Lightning payment hash,
///    Liquid txid, etc.) so a swap row can be cross-referenced with the
///    Transactions table.
///  - metadata: optional JSON blob for provider-specific extras
///    (Breez peg-out fees breakdown, SideSwap order id, etc.).
class Swaps extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sendAsset => text().withLength(min: 1, max: 128)();
  TextColumn get receiveAsset => text().withLength(min: 1, max: 128)();
  Int64Column get sendAmount => int64()();
  Int64Column get receiveAmount => int64()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get provider =>
      text().withLength(min: 1, max: 32).withDefault(const Constant('unknown'))();
  TextColumn get status =>
      text().withLength(min: 1, max: 16).withDefault(const Constant('completed'))();
  TextColumn get direction =>
      text().withLength(min: 1, max: 32).withDefault(const Constant('asset_swap'))();
  TextColumn get txId => text().nullable()();
  TextColumn get metadata => text().nullable()();
  // walletId scopes audit rows to the wallet that produced them. Sourced
  // from WalletIdService at insert time. Default 'unknown' covers rows
  // that pre-date the v10 → v11 migration; those rows remain on disk for
  // audit but are not visible to any active wallet's queries.
  TextColumn get walletId =>
      text().withLength(min: 1, max: 64).withDefault(const Constant('unknown'))();
}

/// Immutable audit log of SideSwap peg-in / peg-out operations.
///
/// IMMUTABILITY INVARIANT (enforced by DAO surface, see [AppDatabase]): no
/// delete or update method is exposed for this table. Pegs are a sub-class
/// of swap and inherit the same audit constraint. See [Swaps] for rationale.
class Pegs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get orderId => text()();
  BoolColumn get pegIn => boolean()();
  TextColumn get sideswapAddress => text()();
  TextColumn get payoutAddress => text()();
  IntColumn get amount => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  // See Swaps.walletId — same scoping policy.
  TextColumn get walletId =>
      text().withLength(min: 1, max: 64).withDefault(const Constant('unknown'))();
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

class FavoritePayerEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get label => text().withLength(min: 1, max: 255)();
  // Unmasked taxpayer id: CPF (11 digits) or CNPJ (14 digits).
  TextColumn get cpf => text().withLength(min: 11, max: 14)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
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
    FavoritePayerEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 13;

  // ==================== Swap Operations (immutable) ====================
  //
  // Append-only by design. Insert and read are the only operations exposed.
  // Do NOT add deleteSwap*, updateSwap (other than status upserts via
  // insertOnConflictUpdate against [Swaps.id]), or truncate methods here.
  // The audit constraint declared on the [Swaps] table is enforced at the
  // DAO surface — keep it that way.

  /// Insert a new swap audit row. Returns the auto-generated id.
  Future<int> insertSwap(SwapsCompanion swap) => into(swaps).insert(swap);

  /// Update the terminal-state fields of a swap row by id.
  ///
  /// This is the ONLY method exposed for mutating an existing swap, and it
  /// is deliberately restricted to status/txId/metadata. The audit-critical
  /// columns (provider, direction, sendAsset, receiveAsset, sendAmount,
  /// receiveAmount, createdAt) are NOT touched here — the invariant is
  /// "the swap that happened cannot be rewritten, only its outcome status
  /// can be updated". Returns the number of rows updated (0 or 1).
  Future<int> updateSwapStatus({
    required int id,
    required String status,
    String? txId,
    String? metadata,
  }) {
    return (update(swaps)..where((s) => s.id.equals(id))).write(
      SwapsCompanion(
        status: Value(status),
        txId: txId != null ? Value(txId) : const Value.absent(),
        metadata: metadata != null ? Value(metadata) : const Value.absent(),
      ),
    );
  }

  /// Returns swap rows scoped to [walletId]. Pre-v11 rows carry the
  /// sentinel walletId 'unknown' and are therefore invisible here; they
  /// remain on disk for audit recoverability.
  Future<List<Swap>> getAllSwaps({required String walletId}) =>
      (select(swaps)..where((s) => s.walletId.equals(walletId))).get();

  /// Idempotency primitive for the audit repository, scoped per-wallet:
  /// returns true if a swap for the given (walletId, provider, txId)
  /// already exists. Matches either an exact txId equality or a substring
  /// inside metadata, so callers that store the reference inside metadata
  /// (e.g. Liquid internal swaps that store both send and receive leg ids
  /// in metadata) hit the same check.
  Future<bool> swapExistsForTxId({
    required String walletId,
    required String provider,
    required String txId,
  }) async {
    final pattern = '%${txId.toLowerCase()}%';
    final query =
        select(swaps)
          ..where((s) => s.walletId.equals(walletId))
          ..where((s) => s.provider.equals(provider))
          ..where(
            (s) => s.txId.equals(txId) | s.metadata.lower().like(pattern),
          )
          ..limit(1);
    final result = await query.getSingleOrNull();
    return result != null;
  }

  /// Lookup primitive used by the Breez peg-in completion listener, scoped
  /// per-wallet: finds the most recent pending peg-in whose metadata
  /// references the given Bitcoin deposit address. Returns null if no
  /// match.
  Future<Swap?> findPendingPegInByDepositAddress({
    required String walletId,
    required String provider,
    required String depositAddress,
  }) async {
    final pattern = '%${depositAddress.toLowerCase()}%';
    final query =
        select(swaps)
          ..where((s) => s.walletId.equals(walletId))
          ..where((s) => s.provider.equals(provider))
          ..where((s) => s.status.equals('pending'))
          ..where((s) => s.metadata.lower().like(pattern))
          ..orderBy([
            (s) =>
                OrderingTerm(expression: s.createdAt, mode: OrderingMode.desc),
          ])
          ..limit(1);
    return query.getSingleOrNull();
  }

  /// Paginated swap query, newest first, scoped by walletId, with optional
  /// provider and search-text filter applied at SQL level (matches
  /// sendAsset, receiveAsset, direction, txId, metadata).
  Future<List<Swap>> getSwapsPaginated({
    required String walletId,
    required int limit,
    required int offset,
    String? provider,
    String? searchQuery,
  }) {
    final query =
        select(swaps)
          ..where((s) => s.walletId.equals(walletId))
          ..orderBy([
            (s) =>
                OrderingTerm(expression: s.createdAt, mode: OrderingMode.desc),
          ])
          ..limit(limit, offset: offset);

    if (provider != null) {
      query.where((s) => s.provider.equals(provider));
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final pattern = '%${searchQuery.toLowerCase()}%';
      query.where(
        (s) =>
            s.sendAsset.lower().like(pattern) |
            s.receiveAsset.lower().like(pattern) |
            s.direction.lower().like(pattern) |
            s.txId.lower().like(pattern) |
            s.metadata.lower().like(pattern),
      );
    }

    return query.get();
  }

  Future<int> getSwapsCount({required String walletId}) async {
    final countExp = swaps.id.count();
    final query =
        selectOnly(swaps)
          ..addColumns([countExp])
          ..where(swaps.walletId.equals(walletId));
    final result = await query.getSingleOrNull();
    return result?.read(countExp) ?? 0;
  }

  // ==================== Peg Operations (immutable) ====================
  //
  // Same audit constraint as [Swaps]. Append-only by design — no delete /
  // truncate methods are exposed.

  /// Insert a new peg audit row. Returns the auto-generated id.
  Future<int> insertPeg(PegsCompanion peg) => into(pegs).insert(peg);

  /// Pegs scoped to [walletId]; pre-v11 rows with sentinel walletId
  /// 'unknown' are invisible.
  Future<List<Peg>> getAllPegs({required String walletId}) =>
      (select(pegs)..where((p) => p.walletId.equals(walletId))).get();

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

  /// Get logs with pagination (newest first), with optional level and
  /// full-text-style search filters applied at the SQL layer so the UI
  /// only ever receives matching rows.
  Future<List<AppLog>> getLogsPaginated({
    required int limit,
    required int offset,
    String? level,
    String? searchQuery,
  }) {
    final query =
        select(appLogs)
          ..orderBy([
            (log) => OrderingTerm(
              expression: log.timestamp,
              mode: OrderingMode.desc,
            ),
          ])
          ..limit(limit, offset: offset);

    if (level != null) {
      query.where((log) => log.level.equals(level));
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      // lower() on both sides keeps matching consistent across cases for the
      // ASCII range, mirroring the previous Dart-side toLowerCase().contains().
      // Search spans message, tag, error and stackTrace so users can find
      // entries by exception text (e.g. "SocketException") not just message.
      // For nullable columns lower(NULL) LIKE ... evaluates to NULL/false, so
      // missing values cannot match.
      final pattern = '%${searchQuery.toLowerCase()}%';
      query.where(
        (log) =>
            log.message.lower().like(pattern) |
            log.tag.lower().like(pattern) |
            log.error.lower().like(pattern) |
            log.stackTrace.lower().like(pattern),
      );
    }

    return query.get();
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

  /// Wipe ALL rows in the Transactions table.
  ///
  /// CONTRACT: only ever called from [WalletDataManager.deleteWallet].
  /// Do NOT call from sync paths, app restart, wallet reload, or "clear
  /// cache" UIs. Cross-wallet transaction leakage was the original reason
  /// this is called on wipe — see DECISIONS.md ADR-010.
  Future<int> deleteAllTransactions() => delete(transactions).go();

  /// Delete all PIX deposits
  Future<int> deleteAllDeposits() => delete(deposits).go();

  // ==================== Favorite Payers ====================
  //
  // Wallet-scoped CRUD. [deleteAllFavoritePayers] is the wallet-isolation
  // sweep, invoked from the Pix cleanup hook on wallet delete/import.

  Future<List<FavoritePayerEntry>> getAllFavoritePayers() =>
      (select(favoritePayerEntries)
            ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
          .get();

  Future<int> insertFavoritePayer(FavoritePayerEntriesCompanion entry) =>
      into(favoritePayerEntries).insert(entry);

  Future<int> updateFavoritePayerById(
    int id,
    FavoritePayerEntriesCompanion entry,
  ) => (update(favoritePayerEntries)..where((p) => p.id.equals(id))).write(entry);

  Future<int> deleteFavoritePayer(int id) =>
      (delete(favoritePayerEntries)..where((p) => p.id.equals(id))).go();

  /// Wipe ALL favorite payers. Wallet-isolation sweep — only ever called from
  /// the wallet cleanup hook on delete/import.
  Future<int> deleteAllFavoritePayers() => delete(favoritePayerEntries).go();

  Future<bool> favoritePayerCpfExists(String cpf, {int? excludingId}) async {
    final query = select(favoritePayerEntries)
      ..where((p) => p.cpf.equals(cpf));
    if (excludingId != null) {
      query.where((p) => p.id.equals(excludingId).not());
    }
    return (await query.get()).isNotEmpty;
  }

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

  /// Wipe ALL rows in the SyncMetadata table.
  ///
  /// CONTRACT: this method is only ever called from
  /// [WalletDataManager.deleteWallet] as part of the wallet-deletion sweep.
  /// It must NEVER be invoked during normal sync, app restart, wallet
  /// reload, or any other code path. If a future caller needs to "reset
  /// sync state" without deleting the wallet, add a scoped DAO method
  /// instead — do not reuse this one.
  Future<int> deleteAllSyncMetadata() => delete(syncMetadata).go();

  /// Indexes that accelerate the logs viewer's paginated, filtered queries:
  ///   - timestamp DESC for the default ORDER BY (every page)
  ///   - (level, timestamp DESC) for the level-filtered case (composite scan)
  /// LIKE-based search over message/tag/error/stackTrace can't use a B-tree
  /// index; an FTS5 virtual table would be the next step if search becomes
  /// the dominant access pattern.
  Future<void> _createLogIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_app_logs_timestamp '
      'ON app_logs(timestamp DESC)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_app_logs_level_timestamp '
      'ON app_logs(level, timestamp DESC)',
    );
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
        await _createLogIndexes();
      },
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
        if (from <= 8 && to >= 9) {
          await _createLogIndexes();
        }
        if (from <= 9 && to >= 10) {
          // The pre-v10 Swaps schema constrained sendAsset/receiveAsset to
          // exactly 64 chars (Liquid asset hash) and lacked provider/status/
          // direction/txId/metadata. Audit confirmed no code path ever wrote
          // to Swaps prior to this migration, so a destructive recreate is
          // safe and avoids the TableMigration ceremony for relaxing a CHECK
          // constraint. If a future migration ever hits a non-empty Swaps
          // table, replace this with a TableMigration that preserves rows.
          await m.deleteTable('swaps');
          await m.createTable(swaps);
        }
        if (from <= 10 && to >= 11) {
          // Add walletId to Swaps and Pegs without losing existing rows.
          // Pre-v11 rows get the sentinel 'unknown'; they remain on disk
          // for audit recoverability but are not visible to any active
          // wallet's scoped queries. New inserts MUST provide a walletId.
          await _addColumnIfMissing(m, swaps, swaps.walletId);
          await _addColumnIfMissing(m, pegs, pegs.walletId);
        }
        if (from <= 11 && to >= 12) {
          // Wallet-scoped favorite payers. New empty table; nothing to
          // backfill. Isolation is by cleanup-on-delete/import.
          await m.createTable(favoritePayerEntries);
        }
        if (from <= 12 && to >= 13) {
          // Relax the tax-id length check (11 -> 11..14) to also accept CNPJ.
          // Recreates the table, preserving existing rows.
          await m.alterTable(TableMigration(favoritePayerEntries));
        }
      },
    );
  }

  Future<void> _addColumnIfMissing(
    Migrator m,
    TableInfo table,
    GeneratedColumn column,
  ) async {
    final rows = await customSelect(
      "PRAGMA table_info('${table.actualTableName}')",
    ).get();
    final exists = rows.any((r) => r.read<String>('name') == column.name);
    if (exists) return;
    await m.addColumn(table, column);
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
