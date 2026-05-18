import 'package:fpdart/fpdart.dart';

import '../../domain/entities/chain.dart';
import '../../domain/failures/failure.dart';
import '../../domain/repositories/notified_tx_registry.dart';
import '../db/transaction_database.dart';

/// Sqlite-backed [NotifiedTxRegistry]. Lives in the same `mooze_v2.db`
/// file as the transaction store so the wallet-delete + import flows
/// can wipe both in one place.
class SqliteNotifiedTxRegistry implements NotifiedTxRegistry {
  SqliteNotifiedTxRegistry(this._database);
  final TransactionDatabase _database;

  static const String _kBaselineKey = 'baseline_completed';
  static const String _kBaselineValueTrue = '1';

  @override
  Future<Either<StorageFailure, bool>> markIfNew({
    required ChainId chain,
    required String txId,
  }) async {
    try {
      // INSERT OR IGNORE returns 0 changes for a duplicate, 1 for a
      // fresh insert. `changes` on the underlying db connection is
      // statement-scoped on sqlite3-dart, but we read it immediately
      // after `execute` while no other statements have run on this
      // connection — single-isolate access keeps it atomic.
      final stmt = _database.db.prepare(
        'INSERT OR IGNORE INTO notified_tx_ids '
        '(chain, tx_id, notified_at_ms) VALUES (?, ?, ?)',
      );
      try {
        stmt.execute([
          chain.name,
          txId,
          DateTime.now().millisecondsSinceEpoch,
        ]);
      } finally {
        stmt.dispose();
      }
      final inserted = _database.db.updatedRows == 1;
      return Right(inserted);
    } catch (e, st) {
      return Left(StorageFailure(
        'notifiedTxRegistry.markIfNew failed: $e',
        cause: e,
        stackTrace: st,
      ));
    }
  }

  @override
  Future<Either<StorageFailure, Unit>> bulkMark(
    Iterable<({ChainId chain, String txId})> entries,
  ) async {
    final list = entries.toList(growable: false);
    if (list.isEmpty) return const Right(unit);
    try {
      _database.db.execute('BEGIN IMMEDIATE');
      final stmt = _database.db.prepare(
        'INSERT OR IGNORE INTO notified_tx_ids '
        '(chain, tx_id, notified_at_ms) VALUES (?, ?, ?)',
      );
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      try {
        for (final e in list) {
          stmt.execute([e.chain.name, e.txId, nowMs]);
        }
      } finally {
        stmt.dispose();
      }
      _database.db.execute('COMMIT');
      return const Right(unit);
    } catch (e, st) {
      try {
        _database.db.execute('ROLLBACK');
      } catch (_) {/* best-effort */}
      return Left(StorageFailure(
        'notifiedTxRegistry.bulkMark failed: $e',
        cause: e,
        stackTrace: st,
      ));
    }
  }

  @override
  Future<Either<StorageFailure, bool>> isBaselineComplete() async {
    try {
      final rows = _database.db.select(
        'SELECT meta_value FROM notification_meta WHERE meta_key = ? LIMIT 1',
        [_kBaselineKey],
      );
      if (rows.isEmpty) return const Right(false);
      return Right(rows.first['meta_value'] == _kBaselineValueTrue);
    } catch (e, st) {
      return Left(StorageFailure(
        'notifiedTxRegistry.isBaselineComplete failed: $e',
        cause: e,
        stackTrace: st,
      ));
    }
  }

  @override
  Future<Either<StorageFailure, Unit>> setBaselineComplete() async {
    try {
      final stmt = _database.db.prepare(
        'INSERT OR REPLACE INTO notification_meta '
        '(meta_key, meta_value) VALUES (?, ?)',
      );
      try {
        stmt.execute([_kBaselineKey, _kBaselineValueTrue]);
      } finally {
        stmt.dispose();
      }
      return const Right(unit);
    } catch (e, st) {
      return Left(StorageFailure(
        'notifiedTxRegistry.setBaselineComplete failed: $e',
        cause: e,
        stackTrace: st,
      ));
    }
  }

  @override
  Future<Either<StorageFailure, Unit>> clear() async {
    try {
      _database.db.execute('BEGIN IMMEDIATE');
      _database.db.execute('DELETE FROM notified_tx_ids');
      _database.db.execute('DELETE FROM notification_meta');
      _database.db.execute('COMMIT');
      return const Right(unit);
    } catch (e, st) {
      try {
        _database.db.execute('ROLLBACK');
      } catch (_) {/* best-effort */}
      return Left(StorageFailure(
        'notifiedTxRegistry.clear failed: $e',
        cause: e,
        stackTrace: st,
      ));
    }
  }
}
