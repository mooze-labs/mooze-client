import 'package:fpdart/fpdart.dart';

import '../../../../domain/entities/wallet_credentials.dart';
import '../../../../domain/failures/failure.dart';
import '../../../../domain/repositories/notified_tx_registry.dart';
import '../../../../domain/repositories/secure_credential_store.dart';
import '../../../../domain/repositories/transaction_store.dart';
import '../../../../domain/repositories/wallet_directory_guard.dart';
import '../../../../shared/diagnostics/boot_tracer.dart';
import '../../../../shared/logging/structured_logger.dart';

/// Stores a fresh mnemonic into the secure credential store. The caller
/// (typically a setup screen) is responsible for triggering
/// AppLifecycleController.start() afterwards.
///
/// **R1 / R2 cross-wallet-leakage hardening.** Before persisting the new
/// mnemonic this use case wipes any prior wallet state that could surface
/// in the freshly imported wallet:
///   - V2 transaction store (mooze_v2.db) — prevents previous wallet's
///     txs from appearing in history.
///   - SDK working directories (lwk-db / breez) — prevents stale chain
///     state from being adopted by the new wallet.
///   - Pre-import callbacks (PIN, pending-tx storage, wallet-id) injected
///     by the composition root.
///
/// All cleanup steps are best-effort. Failures are logged but do not
/// abort the import — partial-state recovery is preferable to a stuck
/// wallet.
class ImportWalletUseCase {
  ImportWalletUseCase(
    this._store, {
    this.transactionStore,
    this.notifiedTxRegistry,
    this.directoryGuard,
    this.workingDirs = const ['lwk-db', 'breez'],
    this.preImportHooks = const [],
    this.logger,
  });

  final SecureCredentialStore _store;
  final TransactionStore? transactionStore;

  /// Persisted notification dedup ledger. Wiped here for the same
  /// reason `transactionStore` is wiped: a re-import on this device
  /// must not carry over the previous wallet's "already notified"
  /// state into the new wallet's first sync (which would silently
  /// absorb every fresh tx).
  final NotifiedTxRegistry? notifiedTxRegistry;

  final WalletDirectoryGuard? directoryGuard;
  final List<String> workingDirs;

  /// Best-effort cleanup callbacks invoked **before** the new mnemonic is
  /// persisted. Production wires these to legacy stores that do not yet
  /// have a V2 abstraction (PIN store, pending-tx SharedPreferences,
  /// wallet-id secure-storage entry).
  final List<Future<void> Function()> preImportHooks;

  final StructuredLogger? logger;

  Future<Either<CredentialFailure, Unit>> call(WalletCredentials creds) async {
    BootTracer.mark('import.usecase.begin');
    logger?.info('wallet.import.begin', {});

    // 1. Run injected pre-import hooks (PIN delete, pending-tx wipe,
    //    wallet-id clear). Best-effort — any failure is logged.
    BootTracer.mark('import.hooks.begin', {'count': preImportHooks.length});
    for (final hook in preImportHooks) {
      try {
        await hook();
      } catch (e) {
        logger?.warn('wallet.import.hook_failed', {'error': '$e'});
      }
    }
    BootTracer.mark('import.hooks.end');

    // 2. Wipe V2 transaction store so we don't surface the previous
    //    wallet's txs. Best-effort.
    final txStore = transactionStore;
    if (txStore != null) {
      BootTracer.mark('import.tx_wipe.begin');
      final wipe = await txStore.deleteAll();
      BootTracer.mark('import.tx_wipe.end',
          {'ok': wipe.isRight()});
      wipe.match(
        (f) => logger?.warn(
            'wallet.import.tx_wipe_failed', {'reason': f.message}),
        (_) => logger?.info('wallet.import.tx_wiped', {}),
      );
    }

    // 2b. Wipe notification dedup ledger + baseline flag so the new
    //     wallet's first sync correctly enters the baseline-absorb
    //     path and does not get masked by a previous wallet's "already
    //     notified" rows. Immediately stamp `wallet_imported_at_ms` so
    //     the notifier can filter out any transaction with an on-chain
    //     timestamp predating this import — those are historical txs
    //     restored from the chain and must not surface as "received"
    //     modals on first sync (or any subsequent re-sync).
    final notifyReg = notifiedTxRegistry;
    if (notifyReg != null) {
      BootTracer.mark('import.notify_wipe.begin');
      final wipe = await notifyReg.clear();
      BootTracer.mark('import.notify_wipe.end',
          {'ok': wipe.isRight()});
      wipe.match(
        (f) => logger?.warn(
            'wallet.import.notified_wipe_failed', {'reason': f.message}),
        (_) => logger?.info('wallet.import.notified_wiped', {}),
      );
      final importedAtMs = DateTime.now().millisecondsSinceEpoch;
      BootTracer.mark('import.stamp.begin');
      final stamp = await notifyReg.setImportedAtMs(importedAtMs);
      BootTracer.mark('import.stamp.end', {'ok': stamp.isRight()});
      stamp.match(
        (f) => logger?.warn(
            'wallet.import.stamp_failed', {'reason': f.message}),
        (_) => logger?.info(
            'wallet.import.stamped', {'imported_at_ms': importedAtMs}),
      );
    }

    // 3. Wipe SDK working directories. Best-effort. The directory guard
    //    re-acquires on the next connect; an in-flight orchestrator must
    //    already be stopped by the caller (the boot orchestrator was
    //    paused at `BootPhase.needsSetup` so nothing is holding the
    //    directories at this point).
    final guard = directoryGuard;
    if (guard != null) {
      for (final dir in workingDirs) {
        BootTracer.mark('import.dir_wipe.begin', {'dir': dir});
        final wipe = await guard.wipe(dir);
        BootTracer.mark('import.dir_wipe.end',
            {'dir': dir, 'ok': wipe.isRight()});
        wipe.match(
          (f) => logger?.warn('wallet.import.dir_wipe_failed',
              {'dir': dir, 'reason': f.message}),
          (_) => logger?.info('wallet.import.dir_wiped', {'dir': dir}),
        );
      }
    }

    // 4. Persist the fresh mnemonic. THIS is the only step whose failure
    //    aborts the import — without credentials the next boot cannot
    //    proceed.
    BootTracer.mark('import.creds_save.begin');
    final saveResult = await _store.save(creds);
    BootTracer.mark('import.creds_save.end', {'ok': saveResult.isRight()});
    saveResult.match(
      (f) => logger?.error('wallet.import.save_failed', {'reason': f.message}),
      (_) => logger?.info('wallet.import.end', {}),
    );
    BootTracer.mark('import.usecase.end', {'ok': saveResult.isRight()});
    return saveResult;
  }
}
