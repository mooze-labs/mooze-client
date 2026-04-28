import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/database/database.dart';
import 'package:mooze_mobile/features/wallet/domain/repositories/swap_audit_repository.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';

const String _logTag = 'SwapAudit';

/// Drift-backed implementation of [SwapAuditRepository].
///
/// Every method is fail-open: any drift error is caught, logged via
/// [AppLoggerService], and surfaced as `Left(errorMessage)`. Callers MUST
/// NOT propagate a Left return into the user-facing error path — record
/// failures are best-effort by design (see Phase 2 spec §6.5, §9).
class SwapAuditRepositoryImpl implements SwapAuditRepository {
  final AppDatabase _db;
  final AppLoggerService _logger;

  SwapAuditRepositoryImpl(this._db, this._logger);

  @override
  Future<Either<String, int>> recordPending({
    required String provider,
    required String direction,
    required String sendAsset,
    required String receiveAsset,
    required BigInt sendAmount,
    required BigInt receiveAmount,
    String? txId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final id = await _db.insertSwap(
        SwapsCompanion.insert(
          sendAsset: sendAsset,
          receiveAsset: receiveAsset,
          sendAmount: sendAmount,
          receiveAmount: receiveAmount,
          provider: Value(provider),
          status: const Value('pending'),
          direction: Value(direction),
          txId: Value(txId),
          metadata: Value(_encodeMetadata(metadata)),
        ),
      );
      _logger.info(
        _logTag,
        'recordPending id=$id provider=$provider direction=$direction',
      );
      return Right(id);
    } catch (e, st) {
      _logger.error(
        _logTag,
        'recordPending failed (provider=$provider, direction=$direction)',
        error: e,
        stackTrace: st,
      );
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, Unit>> markFinal({
    required int id,
    required String status,
    String? txId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final affected = await _db.updateSwapStatus(
        id: id,
        status: status,
        txId: txId,
        metadata: _encodeMetadata(metadata),
      );
      if (affected == 0) {
        _logger.warning(
          _logTag,
          'markFinal: no row matched id=$id (audit row disappeared?)',
        );
        return Left('no swap row with id=$id');
      }
      _logger.info(_logTag, 'markFinal id=$id status=$status');
      return const Right(unit);
    } catch (e, st) {
      _logger.error(
        _logTag,
        'markFinal failed (id=$id, status=$status)',
        error: e,
        stackTrace: st,
      );
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, int>> recordCompleted({
    required String provider,
    required String direction,
    required String sendAsset,
    required String receiveAsset,
    required BigInt sendAmount,
    required BigInt receiveAmount,
    String? txId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Idempotency: if any row already references this (provider, txId)
      // either as the top-level txId or inside metadata, we return the
      // existing id without inserting.
      if (txId != null) {
        final exists = await _db.swapExistsForTxId(
          provider: provider,
          txId: txId,
        );
        if (exists) {
          _logger.info(
            _logTag,
            'recordCompleted skipped (idempotent) provider=$provider txId=$txId',
          );
          // Find the row to return its id; getSwapsPaginated with the txId
          // search returns the same row swapExistsForTxId hit on.
          final matches = await _db.getSwapsPaginated(
            limit: 1,
            offset: 0,
            provider: provider,
            searchQuery: txId,
          );
          if (matches.isNotEmpty) {
            return Right(matches.first.id);
          }
          // Race-condition fallback: row was reported as existing but
          // wasn't returned — fall through to insert. The DB unique key
          // logic will not protect us, so we accept a duplicate in this
          // rare race rather than fail.
        }
      }

      final id = await _db.insertSwap(
        SwapsCompanion.insert(
          sendAsset: sendAsset,
          receiveAsset: receiveAsset,
          sendAmount: sendAmount,
          receiveAmount: receiveAmount,
          provider: Value(provider),
          status: const Value('completed'),
          direction: Value(direction),
          txId: Value(txId),
          metadata: Value(_encodeMetadata(metadata)),
        ),
      );
      _logger.info(
        _logTag,
        'recordCompleted id=$id provider=$provider direction=$direction txId=$txId',
      );
      return Right(id);
    } catch (e, st) {
      _logger.error(
        _logTag,
        'recordCompleted failed (provider=$provider, direction=$direction)',
        error: e,
        stackTrace: st,
      );
      return Left(e.toString());
    }
  }

  String? _encodeMetadata(Map<String, dynamic>? metadata) {
    if (metadata == null || metadata.isEmpty) return null;
    return jsonEncode(metadata);
  }
}
