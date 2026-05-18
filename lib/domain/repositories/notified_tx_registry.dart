import 'package:fpdart/fpdart.dart';

import '../entities/chain.dart';
import '../failures/failure.dart';

/// Persisted dedup ledger for transaction notifications.
///
/// Survives cold restarts so the notifier can answer "have we ever
/// notified the user about this tx, regardless of process boundaries?"
/// without relying on a volatile in-memory `Set<String>`.
///
/// All identifiers are namespaced by [ChainId] because the V2
/// transaction model uses `(id, chain)` as the composite key — the same
/// txid can exist on Lightning and Liquid (submarine swap legs).
abstract interface class NotifiedTxRegistry {
  /// Returns `true` iff this is the first time `txId` for `chain` has
  /// been seen. INSERT OR IGNORE — atomic under concurrent calls. The
  /// caller is expected to treat a `true` result as the cue to emit a
  /// user-facing notification (or absorb-silently during baseline).
  Future<Either<StorageFailure, bool>> markIfNew({
    required ChainId chain,
    required String txId,
  });

  /// Bulk-mark an iterable of (chain, txId) tuples. Used by the baseline
  /// snapshot path so the first-ever sync burst doesn't notify for the
  /// wallet's historical transactions. Wraps the inserts in a single
  /// transaction so the snapshot is atomic against concurrent
  /// [markIfNew] calls from the live event stream.
  Future<Either<StorageFailure, Unit>> bulkMark(
    Iterable<({ChainId chain, String txId})> entries,
  );

  /// True iff the baseline absorb-historical-txs pass has completed for
  /// this wallet. Flipped to `true` once and stays sticky until the
  /// wallet is deleted ([clear]).
  Future<Either<StorageFailure, bool>> isBaselineComplete();
  Future<Either<StorageFailure, Unit>> setBaselineComplete();

  /// Wipe both the dedup ledger and the baseline flag. Called from
  /// `DeleteWalletUseCase` and `ImportWalletUseCase` so a re-import on
  /// the same device starts with a clean state.
  Future<Either<StorageFailure, Unit>> clear();
}
