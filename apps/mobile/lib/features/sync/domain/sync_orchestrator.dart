import 'package:fpdart/fpdart.dart';

import '../../../domain/entities/wallet_credentials.dart';
import '../../../domain/events/sync_outcome.dart';
import '../../../domain/events/transaction_event.dart';
import '../../../domain/failures/failure.dart';
import '../../../domain/types/disposable.dart';
import 'sync_state.dart';
import 'sync_strategy.dart';

/// Single owner of all blockchain sync activity. The only timer in the app.
abstract interface class SyncOrchestrator implements Disposable {
  Stream<SyncState> get state;
  SyncState get currentState;

  /// Merged transaction-event stream across all chains.
  Stream<TransactionEvent> get transactions;

  Future<void> start();

  Future<Either<SyncFailure, SyncOutcome>> refresh({
    SyncStrategy strategy = SyncStrategy.light,
  });

  /// Manual reconnect. Walks every chain service, and for any service whose
  /// state is errored / disconnected, runs `disconnect()` (idempotent) +
  /// `connect(credentials)` again, then triggers a light refresh.
  ///
  /// The legacy equivalent is `WalletDataManager.retryDataSourceConnection`
  /// (which invalidates Riverpod providers and tail-recurses through
  /// `initializeWallet`). The V2 version is centralised at the orchestrator
  /// layer because the orchestrator already owns the per-service mutex
  /// gate — there is exactly one place to retry, and it's serialised with
  /// the periodic ticker by the same `SingleFlight` that protects
  /// `refresh()`.
  ///
  /// Returns `Right(SyncOutcome)` once the post-reconnect refresh
  /// completes. Returns `Left(SyncFailure)` only when EVERY operational
  /// service still fails after reconnect — partial recovery is treated as
  /// success (matches the boot-orchestrator's "soft-degrade if at least
  /// one chain is up" semantic).
  Future<Either<SyncFailure, SyncOutcome>> reconnect({
    required WalletCredentials credentials,
  });

  Future<void> stop();
}
