import 'package:fpdart/fpdart.dart';

import '../../../../domain/failures/failure.dart';
import '../../../../domain/repositories/secure_credential_store.dart';
import '../../../../domain/repositories/transaction_store.dart';
import '../../../../domain/repositories/wallet_directory_guard.dart';
import '../../../../shared/logging/structured_logger.dart';
import '../../../boot/domain/boot_orchestrator.dart';
import '../../../sync/domain/sync_orchestrator.dart';

/// Hard-deletes the wallet:
/// 1. stop sync
/// 2. shutdown boot (disconnect services in order, releases workdirs)
/// 3. wipe transactions
/// 4. delete credentials
/// 5. wipe SDK working directories
///
/// Each step is awaited explicitly. Failures in non-critical steps are
/// logged but do not abort the sequence — partial-state recovery is
/// always preferable to a stuck wallet.
class DeleteWalletUseCase {
  DeleteWalletUseCase({
    required this.boot,
    required this.sync,
    required this.credentials,
    required this.transactionStore,
    required this.directoryGuard,
    required this.workingDirs,
    required this.logger,
  });

  final BootOrchestrator boot;
  final SyncOrchestrator sync;
  final SecureCredentialStore credentials;
  final TransactionStore transactionStore;
  final WalletDirectoryGuard directoryGuard;
  final List<String> workingDirs;
  final StructuredLogger logger;

  Future<Either<Failure, Unit>> call() async {
    logger.info('wallet.delete.begin', {});

    await sync.stop();
    await boot.shutdown();

    final txWipe = await transactionStore.deleteAll();
    txWipe.match(
      (f) => logger.warn('wallet.delete.tx_wipe_failed', {'reason': f.message}),
      (_) => logger.info('wallet.delete.tx_wiped', {}),
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

    logger.info('wallet.delete.end', {});
    return const Right(unit);
  }
}
