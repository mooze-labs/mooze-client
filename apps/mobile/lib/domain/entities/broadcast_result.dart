import 'chain.dart';
import 'transaction.dart';

/// Result of a successful broadcast (on-chain) or completed payment (Lightning).
///
/// The orchestrator's tx pipeline guarantees that [transaction] has already
/// been persisted via `transactionStore.upsert` before the [BroadcastResult]
/// is returned — so any caller that immediately reads the store will see the
/// new row. UI wishing to drive "tx sent" notifications should subscribe to
/// `transactionsStream` rather than polling.
class BroadcastResult {
  const BroadcastResult({
    required this.chain,
    required this.txId,
    required this.transaction,
    this.feePaidSat,
    this.preimage,
  });

  final ChainId chain;

  /// On-chain txid (32-byte hex). For Lightning, this is the payment hash.
  final String txId;

  /// The locally-known transaction state right after broadcast. Status will
  /// typically be `pending` for on-chain and `confirmed` (or `pending`) for
  /// Lightning depending on settlement speed.
  final Transaction transaction;

  /// Actual fee paid (may differ slightly from the estimate).
  final int? feePaidSat;

  /// Lightning preimage proving payment. Null for on-chain.
  final String? preimage;
}
