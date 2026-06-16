import 'package:fpdart/fpdart.dart';

import '../../../../domain/failures/failure.dart';
import '../../../../domain/repositories/notified_tx_registry.dart';
import '../../../../domain/repositories/secure_credential_store.dart';
import '../../../../domain/repositories/transaction_store.dart';
import '../../../../domain/repositories/wallet_directory_guard.dart';
import '../../../../shared/logging/structured_logger.dart';
import '../../../boot/domain/boot_orchestrator.dart';
import '../../../sync/domain/sync_orchestrator.dart';

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
    this.sessionCleanup,
    this.pixCleanup,
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
  final Future<void> Function()? sessionCleanup;
  final Future<void> Function()? pixCleanup;
  final List<Future<void> Function()> postDeleteHooks;

  Future<Either<Failure, Unit>> call() async {
    logger.info('wallet.delete.begin', {});

    await sync.stop();
    await boot.shutdown();
    if (sessionCleanup != null) {
      try {
        await sessionCleanup!();
        logger.info('wallet.delete.session_cleared', {});
      } catch (e) {
        logger.warn('wallet.delete.session_clear_failed', {'error': '$e'});
      }
    }

    if (pixCleanup != null) {
      try {
        await pixCleanup!();
        logger.info('wallet.delete.pix_cleared', {});
      } catch (e) {
        logger.warn('wallet.delete.pix_clear_failed', {'error': '$e'});
      }
    }

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
