import 'package:fpdart/fpdart.dart';

import '../../../../domain/failures/failure.dart';
import '../../../../domain/repositories/wallet_directory_guard.dart';

/// Wipes the SDK working directories (Liquid LWK, Breez Liquid, optionally
/// BDK) used by the chain services. Intended use:
///
/// - **Pre-import cleanup** (G15): legacy `WalletDataManager.cleanBreezDirectory`
///   was called by `import_button.dart` before saving a fresh mnemonic, to
///   ensure a freshly imported wallet doesn't inherit a previous wallet's
///   on-disk state from an earlier install. This use case is the V2-derived
///   replacement.
///
/// - **Post-delete cleanup**: already performed by `DeleteWalletUseCase`,
///   which calls `directoryGuard.wipe(dir)` per working dir after
///   `boot.shutdown()` releases the FFI handles. This use case is therefore
///   only needed at the *pre*-import edge.
///
/// CRITICAL preconditions (must be satisfied by the caller):
///   1. The orchestrator MUST be stopped before this runs. Wiping a
///      directory while LWK / Breez has an open file handle in it leaves
///      orphaned files and can corrupt the SQLite WAL. The use case does
///      NOT enforce this — it cannot, because injecting the orchestrator
///      here would couple the use case to the sync layer just to call
///      `stop()`. The right place to enforce it is the calling flow (the
///      import-loading screen, in Phase 2.3.3).
///   2. The acquired-directory locks held by `WalletDirectoryGuard` MUST
///      be released before wipe. `wipe()` does not call `release()` for
///      you. Again, callers ensure this by stopping the orchestrator first.
///
/// Failure semantics: best-effort. The legacy code retried each directory
/// up to 5 times with exponential backoff to ride over iOS file-handle
/// release lag — that retry behaviour belongs inside
/// `WalletDirectoryGuardImpl.wipe`, not here. This use case stops at the
/// first failure and surfaces it; the caller decides whether to retry the
/// whole sequence.
class CleanWorkingDirsUseCase {
  CleanWorkingDirsUseCase({
    required this.directoryGuard,
    required this.workingDirs,
  });

  final WalletDirectoryGuard directoryGuard;

  /// The working-directory relative paths to wipe. Production wiring uses
  /// `['lwk-db', 'breez', 'bdk-db']` to match the three chain-service
  /// constructors. BDK was added once it moved off `DatabaseConfig.memory()`
  /// to persistent sqlite, so its wallet.sqlite needs to be wiped on
  /// delete-and-reimport like the LWK / Breez working dirs.
  final List<String> workingDirs;

  Future<Either<Failure, Unit>> call() async {
    for (final dir in workingDirs) {
      final result = await directoryGuard.wipe(dir);
      if (result.isLeft()) {
        return result.map((_) => unit);
      }
    }
    return const Right(unit);
  }
}
