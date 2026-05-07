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
        PRIMARY KEY (id, chain)
      );
    ''');
    db.execute('''
      CREATE INDEX IF NOT EXISTS idx_tx_chain_ts
        ON transactions (chain, timestamp_ms DESC);
    ''');
  }

  void close() => _db.dispose();
}
