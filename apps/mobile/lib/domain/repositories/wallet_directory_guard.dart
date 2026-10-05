import 'package:fpdart/fpdart.dart';

import '../failures/failure.dart';

/// Process-local lock around wallet working directories (Breez, LWK, BDK).
/// Prevents two service instances (e.g. on hot reload or reimport) from
/// holding the same SDK working directory concurrently.
abstract interface class WalletDirectoryGuard {
  /// Returns the absolute path of the requested directory, ensuring it
  /// exists and locking it for the caller.
  Future<Either<StorageFailure, String>> acquire(String relativePath);
  Future<void> release(String relativePath);
  Future<Either<StorageFailure, Unit>> wipe(String relativePath);
}
