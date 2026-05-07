import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:sqlite3/sqlite3.dart' show Row;

import '../../domain/entities/chain.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/failures/failure.dart';
import '../../domain/repositories/transaction_store.dart';
import '../db/transaction_database.dart';

class SqliteTransactionStore implements TransactionStore {
  SqliteTransactionStore(this._database);
  final TransactionDatabase _database;

  final StreamController<List<Transaction>> _watchController =
      StreamController<List<Transaction>>.broadcast();
  bool _disposed = false;

  @override
  Future<Either<StorageFailure, Unit>> upsert(Transaction tx) async {
    return upsertAll([tx]);
  }

  @override
  Future<Either<StorageFailure, Unit>> upsertAll(List<Transaction> txs) async {
    if (_disposed) {
      return Left(const StorageFailure('store disposed'));
    }
    if (txs.isEmpty) return const Right(unit);
    try {
      final stmt = _database.db.prepare('''
        INSERT INTO transactions
          (id, chain, direction, status, amount_sat, fee_sat, timestamp_ms,
           confirmations, asset_id, address, label)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id, chain) DO UPDATE SET
          direction = excluded.direction,
          status = excluded.status,
          amount_sat = excluded.amount_sat,
          fee_sat = excluded.fee_sat,
          timestamp_ms = excluded.timestamp_ms,
          confirmations = excluded.confirmations,
          asset_id = excluded.asset_id,
          address = excluded.address,
          label = excluded.label
      ''');
      try {
        for (final tx in txs) {
          stmt.execute([
            tx.id,
            tx.chain.name,
            tx.direction.name,
            tx.status.name,
            tx.amountSat,
            tx.feeSat,
            tx.timestamp.millisecondsSinceEpoch,
            tx.confirmations,
            tx.assetId,
            tx.address,
            tx.label,
          ]);
        }
      } finally {
        stmt.dispose();
      }
      _scheduleWatchEmit();
      return const Right(unit);
    } catch (e, st) {
      return Left(StorageFailure('upsert failed: $e', cause: e, stackTrace: st));
    }
  }

  @override
  Future<Either<StorageFailure, Transaction?>> findById(String id) async {
    try {
      final r = _database.db.select(
        'SELECT * FROM transactions WHERE id = ? LIMIT 1',
        [id],
      );
      if (r.isEmpty) return const Right(null);
      return Right(_rowToTx(r.first));
    } catch (e, st) {
      return Left(StorageFailure('findById failed: $e', cause: e, stackTrace: st));
    }
  }

  @override
  Future<Either<StorageFailure, List<Transaction>>> list({
    ChainFilter? filter,
    int? limit,
  }) async {
    try {
      final whereClause = filter == null
          ? ''
          : 'WHERE chain IN (${filter.chains.map((_) => '?').join(',')})';
      final params = filter == null
          ? <Object?>[]
          : filter.chains.map((c) => c.name).toList();
      final limitClause = limit == null ? '' : 'LIMIT $limit';
      final rows = _database.db.select(
        'SELECT * FROM transactions $whereClause '
        'ORDER BY timestamp_ms DESC $limitClause',
        params,
      );
      return Right(rows.map(_rowToTx).toList());
    } catch (e, st) {
      return Left(StorageFailure('list failed: $e', cause: e, stackTrace: st));
    }
  }

  @override
  Stream<List<Transaction>> watch({ChainFilter? filter}) async* {
    final initial = await list(filter: filter);
    yield initial.getOrElse((_) => const <Transaction>[]);
    yield* _watchController.stream.asyncMap((_) async {
      final next = await list(filter: filter);
      return next.getOrElse((_) => const <Transaction>[]);
    });
  }

  @override
  Future<Either<StorageFailure, Unit>> deleteAll() async {
    try {
      _database.db.execute('DELETE FROM transactions');
      _scheduleWatchEmit();
      return const Right(unit);
    } catch (e, st) {
      return Left(StorageFailure('deleteAll failed: $e', cause: e, stackTrace: st));
    }
  }

  Transaction _rowToTx(Row r) {
    return Transaction(
      id: r['id'] as String,
      chain: ChainId.values.byName(r['chain'] as String),
      direction:
          TransactionDirection.values.byName(r['direction'] as String),
      status: TransactionStatus.values.byName(r['status'] as String),
      amountSat: (r['amount_sat'] as int),
      feeSat: (r['fee_sat'] as int),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
          (r['timestamp_ms'] as int)),
      confirmations: (r['confirmations'] as int?) ?? 0,
      assetId: r['asset_id'] as String?,
      address: r['address'] as String?,
      label: r['label'] as String?,
    );
  }

  void _scheduleWatchEmit() {
    if (_watchController.isClosed) return;
    // Coalesce bursts: schedule on next microtask.
    scheduleMicrotask(() {
      if (!_watchController.isClosed) _watchController.add(const []);
    });
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    if (!_watchController.isClosed) await _watchController.close();
  }
}
