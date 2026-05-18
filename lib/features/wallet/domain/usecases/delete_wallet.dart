import 'package:fpdart/fpdart.dart';

import '../../../../domain/failures/failure.dart';
import '../../../../domain/repositories/notified_tx_registry.dart';
import '../../../../domain/repositories/secure_credential_store.dart';
import '../../../../domain/repositories/transaction_store.dart';
import '../../../../domain/repositories/wallet_directory_guard.dart';
import '../../../../shared/logging/structured_logger.dart';
import '../../../boot/domain/boot_orchestrator.dart';
import '../../../sync/domain/sync_orchestrator.dart';

/// Hard-deletes the wallet:
/// 1. stop sync
/// 2. shutdown boot (disconnect services in order, releases workdirs)
/// 3. wipe transactions (V2 mooze_v2.db)
/// 4. delete credentials (the `mnemonic_mainWallet` secure-storage key)
/// 5. wipe SDK working directories (lwk-db, breez)
/// 6. invoke post-delete hooks (PIN, pending-tx storage, wallet-id, …)
///
/// Each step is awaited explicitly. Failures in non-critical steps are
/// logged but do not abort the sequence — partial-state recovery is
/// always preferable to a stuck wallet.
///
/// Step 6 (post-delete hooks) is the V2 home for cleanup that used to
/// live inside the 11-step legacy `WalletDataManager.deleteWallet`:
/// PIN salt + hashed PIN deletion, pending-tx SharedPreferences wipe,
/// wallet-id secure-storage clear. The composition root injects these
/// as closures so the use case stays decoupled from the legacy stores.
class DeleteWalletUseCase {
  DeleteWalletUseCase({
    required this.boot,
    required this.sync,
    required this.credentials,
    required this.transactionStore,
    required this.notifiedTxRegistry,
    required this.directoryGuard,
    required this.workingDirs,
    required this.logger,
    this.postDeleteHooks = const [],
  });

  final BootOrchestrator boot;
  final SyncOrchestrator sync;
  final SecureCredentialStore credentials;
  final TransactionStore transactionStore;
  final NotifiedTxRegistry notifiedTxRegistry;
  final WalletDirectoryGuard directoryGuard;
  final List<String> workingDirs;
  final StructuredLogger logger;

  /// Best-effort cleanup callbacks invoked **after** the V2 wipe is
  /// complete. Production wires these to legacy stores that do not yet
  /// have a V2 abstraction (PIN store, pending-tx SharedPreferences,
  /// wallet-id secure-storage entry).
  final List<Future<void> Function()> postDeleteHooks;

  Future<Either<Failure, Unit>> call() async {
    logger.info('wallet.delete.begin', {});

    await sync.stop();
    await boot.shutdown();

    final txWipe = await transactionStore.deleteAll();
    txWipe.match(
      (f) => logger.warn('wallet.delete.tx_wipe_failed', {'reason': f.message}),
      (_) => logger.info('wallet.delete.tx_wiped', {}),
    );

    // Notification dedup ledger lives in the same db file but is owned
    // by its own table. Clear it explicitly so a re-import on this
    // device starts with `baseline_completed=false` and no leftover
    // `notified_tx_ids` rows.
    final notifyWipe = await notifiedTxRegistry.clear();
    notifyWipe.match(
      (f) => logger.warn('wallet.delete.notified_wipe_failed',
          {'reason': f.message}),
      (_) => logger.info('wallet.delete.notified_wiped', {}),
    );

    final credDelete = await credentials.delete();
    if (credDelete.isLeft()) {
      final f = credDelete.swap().getOrElse((_) =>
          const CredentialFailure('credential delete failed'));
      logger.error('wallet.delete.cred_delete_failed', {'reason': f.message});
      return Left<Failure, Unit>(f);
    }
    logger.info('wallet.delete.creds_wiped', {});

    for (final dir in workingDirs) {
      final wipe = await directoryGuard.wipe(dir);
      wipe.match(
        (f) => logger.warn('wallet.delete.dir_wipe_failed',
            {'dir': dir, 'reason': f.message}),
        (_) => logger.info('wallet.delete.dir_wiped', {'dir': dir}),
      );
    }

    // Post-delete hooks (PIN, pending-tx, wallet-id, …). Best-effort.
    for (final hook in postDeleteHooks) {
      try {
        await hook();
      } catch (e) {
        logger.warn('wallet.delete.hook_failed', {'error': '$e'});
      }
    }

    logger.info('wallet.delete.end', {});
    return const Right(unit);
  }
}
