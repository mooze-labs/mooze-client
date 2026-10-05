import 'package:fpdart/fpdart.dart';

/// Domain contract for the immutable swap audit log.
///
/// Every swap-producing flow (Breez peg-in/out, Liquid asset swap detection,
/// future SideSwap integration) writes through this contract. The
/// implementation is fail-open: a database error never blocks the underlying
/// wallet operation, callers receive a `Left(errorMessage)` and are expected
/// to log it.
///
/// Immutability invariant (see DECISIONS.md ADR-008):
///  - There is no delete method, and there will never be one.
///  - [markFinal] updates the `status` of an existing row keyed by [id].
///    The implementation uses `INSERT OR REPLACE` against the auto-increment
///    primary key, which cannot remove a row.
abstract class SwapAuditRepository {
  /// Record a swap that has been initiated but not yet settled.
  /// Returns the row id; use it later with [markFinal].
  ///
  /// [provider]      "breez" | "sideswap" | "internal_liquid" | future
  /// [direction]     short label, free-form ("lbtc_to_btc", "asset_swap", …)
  /// [sendAsset]     provider-defined sender asset id (Liquid hash, "BTC", …)
  /// [receiveAsset]  provider-defined receiver asset id
  /// [sendAmount]    smallest unit (satoshis); promoted to Int64 in storage
  /// [receiveAmount] smallest unit
  /// [txId]          optional cross-reference into Transactions.id
  /// [metadata]      optional provider-specific extras (will be JSON-encoded)
  Future<Either<String, int>> recordPending({
    required String provider,
    required String direction,
    required String sendAsset,
    required String receiveAsset,
    required BigInt sendAmount,
    required BigInt receiveAmount,
    String? txId,
    Map<String, dynamic>? metadata,
  });

  /// Update an existing swap row to a terminal state. The [id] must come
  /// from a prior [recordPending] call.
  ///
  /// [status] must be either "completed" or "failed". Other values are
  /// accepted but undefined for downstream consumers.
  Future<Either<String, Unit>> markFinal({
    required int id,
    required String status,
    String? txId,
    Map<String, dynamic>? metadata,
  });

  /// Record a swap that was detected post-hoc (e.g. by the Liquid swap
  /// matcher) and is already in a terminal state. Idempotent: if a row with
  /// the same provider+txId already exists, returns the existing row's id
  /// and does not insert.
  Future<Either<String, int>> recordCompleted({
    required String provider,
    required String direction,
    required String sendAsset,
    required String receiveAsset,
    required BigInt sendAmount,
    required BigInt receiveAmount,
    String? txId,
    Map<String, dynamic>? metadata,
  });
}
