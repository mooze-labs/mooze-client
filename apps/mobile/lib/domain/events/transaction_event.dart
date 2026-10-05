import '../entities/chain.dart';
import '../entities/transaction.dart';

enum TransactionEventKind { created, statusChanged, confirmationsChanged }

/// Emitted by chain services when their internal view of a transaction
/// changes. The sync orchestrator persists these into the [TransactionStore].
class TransactionEvent {
  const TransactionEvent({
    required this.kind,
    required this.transaction,
    required this.observedAt,
    this.previousStatus,
    this.previousConfirmations,
  });

  final TransactionEventKind kind;
  final Transaction transaction;
  final DateTime observedAt;
  final TransactionStatus? previousStatus;
  final int? previousConfirmations;

  ChainId get chain => transaction.chain;
}
