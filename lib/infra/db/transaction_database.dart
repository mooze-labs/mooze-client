import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// Thin wrapper around a single SQLite file. Owned by [SqliteTransactionStore].
class TransactionDatabase {
  TransactionDatabase._(this._db, this.path);
  final Database _db;
  final String path;

  Database get db => _db;

  static Future<TransactionDatabase> open({String fileName = 'mooze_v2.db'}) async {
    final dir = await getApplicationSupportDirectory();
    final sep = Platform.pathSeparator;
    final dbDir = Directory('${dir.path}${sep}mooze_v2');
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }
    final path = '${dbDir.path}$sep$fileName';
    final db = sqlite3.open(path);
    _migrate(db);
    return TransactionDatabase._(db, path);
  }

  static void _migrate(Database db) {
    db.execute('PRAGMA journal_mode = WAL;');
    db.execute('PRAGMA foreign_keys = ON;');
    db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id TEXT NOT NULL,
        chain TEXT NOT NULL,
        direction TEXT NOT NULL,
        status TEXT NOT NULL,
        amount_sat INTEGER NOT NULL,
        fee_sat INTEGER NOT NULL,
        timestamp_ms INTEGER NOT NULL,
        confirmations INTEGER NOT NULL DEFAULT 0,
        asset_id TEXT,
        address TEXT,
        label TEXT,
        from_asset_id TEXT,
        to_asset_id TEXT,
        sent_amount_sat INTEGER,
        received_amount_sat INTEGER,
        source TEXT,
        PRIMARY KEY (id, chain)
      );
    ''');
    db.execute('''
      CREATE INDEX IF NOT EXISTS idx_tx_chain_ts
        ON transactions (chain, timestamp_ms DESC);
    ''');
    // Phase 2b (swap-pair surface) migration: ALTER columns for
    // databases created before the swap fields existed. New installs
    // get the columns via the CREATE TABLE above; existing installs
    // get them via these ALTERs. SQLite throws "duplicate column" if
    // the column already exists — we swallow that since the migration
    // is idempotent and the per-open() invocation must succeed
    // regardless of prior db state.
    _addColumnIfMissing(db, 'transactions', 'from_asset_id', 'TEXT');
    _addColumnIfMissing(db, 'transactions', 'to_asset_id', 'TEXT');
    _addColumnIfMissing(db, 'transactions', 'sent_amount_sat', 'INTEGER');
    _addColumnIfMissing(db, 'transactions', 'received_amount_sat', 'INTEGER');
    // Source-aware persistence migration (2026-05-18). Adds a `source`
    // column so the upsert can do field-level merge: LWK-authoritative
    // fields lock when source='lwk', Breez/BDK metadata is preserved
    // via COALESCE when LWK hasn't written yet. Legacy rows have
    // source=NULL, which the merge SQL treats as "not LWK" so the
    // first LWK write after deploy overrides them (desired —
    // historical rows were classified under the pre-source rules).
    _addColumnIfMissing(db, 'transactions', 'source', 'TEXT');
    // Notification dedup ledger. One row per (chain, tx_id) the notifier
    // has already processed — either as an emitted user-facing modal or
    // as a silently absorbed baseline entry. INSERT OR IGNORE keeps this
    // atomic and idempotent under concurrent sync events.
    db.execute('''
      CREATE TABLE IF NOT EXISTS notified_tx_ids (
        chain TEXT NOT NULL,
        tx_id TEXT NOT NULL,
        notified_at_ms INTEGER NOT NULL,
        PRIMARY KEY (chain, tx_id)
      );
    ''');
    // Key/value metadata used by the notifier's state machine.
    // Keys currently in use:
    //   - 'baseline_completed' → '1' once the first-ever post-deploy sync
    //     burst has been absorbed.
    db.execute('''
      CREATE TABLE IF NOT EXISTS notification_meta (
        meta_key TEXT PRIMARY KEY,
        meta_value TEXT NOT NULL
      );
    ''');
  }

  void close() => _db.dispose();

  /// Idempotent `ALTER TABLE ... ADD COLUMN`. SQLite has no
  /// `IF NOT EXISTS` for `ADD COLUMN`, so we check the current schema
  /// via `PRAGMA table_info` first. Cheaper than a try/catch over the
  /// ALTER itself (which would still log a SQLite error to stderr on
  /// each app start once the column exists).
  static void _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String type,
  ) {
    final rows = db.select('PRAGMA table_info($table)');
    final exists = rows.any((r) => (r['name'] as String?) == column);
    if (exists) return;
    db.execute('ALTER TABLE $table ADD COLUMN $column $type');
  }
}
