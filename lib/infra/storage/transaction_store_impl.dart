import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:sqlite3/sqlite3.dart' show Row;

import '../../domain/entities/chain.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/failures/failure.dart';
import '../../domain/repositories/transaction_store.dart';
import '../../shared/diagnostics/boot_tracer.dart';
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
    final tUpsert = DateTime.now();
    try {
      // Source-aware merge semantics (2026-05-18 redesign).
      //
      // Rationale: a single (id, chain) row can be written by multiple
      // services (LWK + Breez both watch the same Liquid descriptor;
      // Breez sees peg-ins/outs alongside BDK). Pre-redesign the
      // upsert blindly overwrote everything, producing the
      // "row mutates a few seconds after first render" UX bug when
      // services raced. Post-redesign the upsert distinguishes:
      //
      //   - AUTHORITATIVE fields (direction, status, amount_sat,
      //     fee_sat, confirmations, asset_id, timestamp_ms): LWK is
      //     the final word for chain=liquid. Once a row has
      //     source='lwk', a non-LWK write CANNOT overwrite these.
      //     LWK can always overwrite. Pre-LWK (degraded mode), the
      //     newer write wins normally.
      //
      //   - METADATA fields (address, label, from_asset_id,
      //     to_asset_id, sent_amount_sat, received_amount_sat):
      //     COALESCE(excluded, existing). New non-null wins; null
      //     leaves the existing value alone. Lets LWK fill in
      //     swap-pair details without erasing user labels or
      //     addresses Breez populated.
      //
      //   - SOURCE column itself: monotonic toward 'lwk'. Once LWK
      //     has written, source stays 'lwk' even if a later Breez
      //     write touches the row (rejected by the authoritative
      //     CASE WHEN, but the field merge for metadata still runs).
      //
      // Implementation detail: SQLite's `excluded` and the conflict
      // row are both accessible inside `ON CONFLICT DO UPDATE`. The
      // CASE WHEN checks compare `transactions.source` (the existing
      // row's source — NULL for legacy rows pre-migration, treated
      // as "not LWK") against `excluded.source` (the incoming write).
      final stmt = _database.db.prepare('''
        INSERT INTO transactions
          (id, chain, direction, status, amount_sat, fee_sat, timestamp_ms,
           confirmations, asset_id, address, label,
           from_asset_id, to_asset_id, sent_amount_sat, received_amount_sat,
           source)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id, chain) DO UPDATE SET
          -- Source bookkeeping: monotonically toward 'lwk'.
          source = CASE
            WHEN excluded.source = 'lwk' THEN 'lwk'
            WHEN transactions.source = 'lwk' THEN 'lwk'
            ELSE excluded.source
          END,
          -- Authoritative fields: LWK locks once it has written; any
          -- other writer is rejected for these specific fields. If
          -- existing source is NOT 'lwk', newer write wins (normal
          -- upsert behaviour, degraded mode).
          direction = CASE
            WHEN transactions.source = 'lwk' AND excluded.source != 'lwk'
              THEN transactions.direction
            ELSE excluded.direction
          END,
          status = CASE
            WHEN transactions.source = 'lwk' AND excluded.source != 'lwk'
              THEN transactions.status
            ELSE excluded.status
          END,
          amount_sat = CASE
            WHEN transactions.source = 'lwk' AND excluded.source != 'lwk'
              THEN transactions.amount_sat
            ELSE excluded.amount_sat
          END,
          fee_sat = CASE
            WHEN transactions.source = 'lwk' AND excluded.source != 'lwk'
              THEN transactions.fee_sat
            ELSE excluded.fee_sat
          END,
          confirmations = CASE
            WHEN transactions.source = 'lwk' AND excluded.source != 'lwk'
              THEN transactions.confirmations
            ELSE excluded.confirmations
          END,
          asset_id = CASE
            WHEN transactions.source = 'lwk' AND excluded.source != 'lwk'
              THEN transactions.asset_id
            ELSE excluded.asset_id
          END,
          timestamp_ms = CASE
            WHEN transactions.source = 'lwk' AND excluded.source != 'lwk'
              THEN transactions.timestamp_ms
            ELSE excluded.timestamp_ms
          END,
          -- Metadata fields: newer non-null wins, otherwise preserve
          -- existing. Lets LWK populate swap-pair info without
          -- nuking labels/addresses Breez wrote, and vice versa.
          address = COALESCE(excluded.address, transactions.address),
          label = COALESCE(excluded.label, transactions.label),
          from_asset_id =
            COALESCE(excluded.from_asset_id, transactions.from_asset_id),
          to_asset_id =
            COALESCE(excluded.to_asset_id, transactions.to_asset_id),
          sent_amount_sat =
            COALESCE(excluded.sent_amount_sat, transactions.sent_amount_sat),
          received_amount_sat =
            COALESCE(excluded.received_amount_sat,
                     transactions.received_amount_sat)
      ''');
      final tExec = DateTime.now();
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
            tx.fromAssetId,
            tx.toAssetId,
            tx.sentAmountSat,
            tx.receivedAmountSat,
            tx.source?.name,
          ]);
        }
      } finally {
        stmt.dispose();
      }
      final execMs = DateTime.now().difference(tExec).inMilliseconds;
      final totalMs = DateTime.now().difference(tUpsert).inMilliseconds;
      // Only surface batches that are non-trivial — single-row upserts
      // happen many times per second during sync and would drown the
      // trace. Threshold is intentionally low so we still see the
      // start of any pathological run.
      if (txs.length >= 5 || execMs >= 2) {
        BootTracer.mark('tx_store.upsert', {
          'n': txs.length,
          'exec_ms': execMs,
          'total_ms': totalMs,
        });
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
    BootTracer.mark('tx_store.watch.subscribed', {
      'filter': filter?.toString() ?? 'null',
    });
    final tInit = DateTime.now();
    final initial = await list(filter: filter);
    final initialList = initial.getOrElse((_) => const <Transaction>[]);
    BootTracer.mark('tx_store.watch.initial_yield', {
      'len': initialList.length,
      'dur_ms': DateTime.now().difference(tInit).inMilliseconds,
    });
    yield initialList;
    var emitSeq = 0;
    yield* _watchController.stream.asyncMap((_) async {
      emitSeq += 1;
      final tQuery = DateTime.now();
      final next = await list(filter: filter);
      final nextList = next.getOrElse((_) => const <Transaction>[]);
      BootTracer.mark('tx_store.watch.requery', {
        'n': emitSeq,
        'len': nextList.length,
        'dur_ms': DateTime.now().difference(tQuery).inMilliseconds,
      });
      return nextList;
    });
  }

  @override
  Future<Either<StorageFailure, Unit>> deleteAll() async {
    try {
      BootTracer.mark('tx_store.delete_all.begin');
      _database.db.execute('DELETE FROM transactions');
      BootTracer.mark('tx_store.delete_all.executed');
      _scheduleWatchEmit();
      BootTracer.mark('tx_store.delete_all.end');
      return const Right(unit);
    } catch (e, st) {
      return Left(StorageFailure('deleteAll failed: $e', cause: e, stackTrace: st));
    }
  }

  Transaction _rowToTx(Row r) {
    // Swap-pair and source columns are nullable and were added by
    // later migrations — pre-migration rows return null for them,
    // which is semantically correct (no swap data / no known origin).
    final sourceStr = r['source'] as String?;
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
      fromAssetId: r['from_asset_id'] as String?,
      toAssetId: r['to_asset_id'] as String?,
      sentAmountSat: r['sent_amount_sat'] as int?,
      receivedAmountSat: r['received_amount_sat'] as int?,
      source: sourceStr == null
          ? null
          : TransactionSource.values
              .where((s) => s.name == sourceStr)
              .firstOrNull,
    );
  }

  int _pendingWrites = 0;
  bool _emitScheduled = false;

  void _scheduleWatchEmit() {
    if (_watchController.isClosed) return;
    _pendingWrites += 1;
    if (_emitScheduled) return;
    _emitScheduled = true;
    // Coalesce bursts: schedule on next microtask.
    scheduleMicrotask(() {
      final coalesced = _pendingWrites;
      _pendingWrites = 0;
      _emitScheduled = false;
      if (_watchController.isClosed) return;
      BootTracer.mark('tx_store.watch.emit', {'coalesced_writes': coalesced});
      _watchController.add(const []);
    });
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    if (!_watchController.isClosed) await _watchController.close();
  }
}
