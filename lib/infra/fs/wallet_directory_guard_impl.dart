import 'dart:async';
import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/failures/failure.dart';
import '../../domain/repositories/wallet_directory_guard.dart';

/// Process-local directory lock. Prevents two service instances from holding
/// the same SDK working dir concurrently (hot reload, reimport flows).
class WalletDirectoryGuardImpl implements WalletDirectoryGuard {
  WalletDirectoryGuardImpl({this.rootSubdir = 'mooze_v2'});
  final String rootSubdir;
  final Map<String, Completer<void>> _locks = {};

  @override
  Future<Either<StorageFailure, String>> acquire(String relativePath) async {
    try {
      final absolute = await _resolve(relativePath);
      // Wait for existing lock to release.
      while (_locks[absolute] != null) {
        await _locks[absolute]!.future;
      }
      _locks[absolute] = Completer<void>();

      final dir = Directory(absolute);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return Right(absolute);
    } catch (e, st) {
      return Left(StorageFailure('acquire failed: $e', cause: e, stackTrace: st));
    }
  }

  @override
  Future<void> release(String relativePath) async {
    try {
      final absolute = await _resolve(relativePath);
      final lock = _locks.remove(absolute);
      if (lock != null && !lock.isCompleted) {
        lock.complete();
      }
    } catch (_) {/* releasing must not throw */}
  }

  @override
  Future<Either<StorageFailure, Unit>> wipe(String relativePath) async {
    try {
      final absolute = await _resolve(relativePath);
      // Wait briefly for an in-progress holder to release; past the cap
      // we forcibly drop the lock and proceed. The wipe is the
      // user-visible deletion — we cannot leave it stuck because of an
      // in-memory lock that the holder never released (e.g., V2
      // `liquid.disconnect()` timed out without running its body
      // because its `_connectMutex` was wedged behind a hung FFI call).
      // On the next boot the wallet starts from a clean slate.
      final lock = _locks[absolute];
      if (lock != null) {
        try {
          await lock.future.timeout(const Duration(seconds: 3));
        } on TimeoutException {
          if (!lock.isCompleted) lock.complete();
        }
        _locks.remove(absolute);
      }
      final dir = Directory(absolute);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      return const Right(unit);
    } catch (e, st) {
      return Left(StorageFailure('wipe failed: $e', cause: e, stackTrace: st));
    }
  }

  Future<String> _resolve(String relativePath) async {
    final docs = await getApplicationDocumentsDirectory();
    final sep = Platform.pathSeparator;
    return '${docs.path}$sep$rootSubdir$sep$relativePath';
  }
}
