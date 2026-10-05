import 'dart:async';
import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/failures/failure.dart';
import '../../domain/repositories/wallet_directory_guard.dart';
import '../../shared/diagnostics/boot_tracer.dart';
import '../../shared/platform/platform_warmup.dart';

/// Process-local directory lock. Prevents two service instances from holding
/// the same SDK working dir concurrently (hot reload, reimport flows).
class WalletDirectoryGuardImpl implements WalletDirectoryGuard {
  WalletDirectoryGuardImpl({this.rootSubdir = 'mooze_v2'});
  final String rootSubdir;
  final Map<String, Completer<void>> _locks = {};

  /// Documents-directory path is stable across the app session — cache the
  /// first resolution so subsequent `acquire()` calls don't pay the
  /// platform-channel cost again. Profiled hot-restarts on the iOS
  /// simulator showed `getApplicationDocumentsDirectory()` taking ~1.5s
  /// on the first call after a Dart-side restart; with three chains
  /// (liquid/bitcoin/lightning) acquiring in parallel during boot, the
  /// cost serialised on the platform channel to ~4.6s of UI-thread
  /// block. The cache makes the cost a one-shot.
  Future<String>? _docsPathFuture;
  Future<String> _docsPath() {
    return _docsPathFuture ??= getApplicationDocumentsDirectory()
        .then((d) => d.path);
  }

  @override
  Future<Either<StorageFailure, String>> acquire(String relativePath) async {
    final tBegin = DateTime.now();
    try {
      final tResolve = DateTime.now();
      final absolute = await _resolve(relativePath);
      BootTracer.mark('dir_guard.resolve', {
        'rel': relativePath,
        'dur_ms': DateTime.now().difference(tResolve).inMilliseconds,
      });
      // Wait for existing lock to release.
      final tLock = DateTime.now();
      while (_locks[absolute] != null) {
        await _locks[absolute]!.future;
      }
      final lockMs = DateTime.now().difference(tLock).inMilliseconds;
      _locks[absolute] = Completer<void>();

      // Wait for the iOS data-protection sandbox to unlock before the
      // first FS read. `PlatformWarmup.start()` (called from `main()`)
      // kicked off a parallel `exists()` on the docs root the moment
      // bindings were ready, so by the time we reach here the warmup
      // is usually already complete and this await is a no-op. When
      // the V2 boot is fast enough that we beat the warmup, the await
      // amortises the OS unlock cost across all three chains rather
      // than charging each one independently.
      final tFsWarmup = DateTime.now();
      await PlatformWarmup.awaitFs();
      final fsWarmupMs =
          DateTime.now().difference(tFsWarmup).inMilliseconds;

      final tExists = DateTime.now();
      final dir = Directory(absolute);
      final exists = await dir.exists();
      final existsMs =
          DateTime.now().difference(tExists).inMilliseconds;
      var createMs = 0;
      if (!exists) {
        final tCreate = DateTime.now();
        await dir.create(recursive: true);
        createMs = DateTime.now().difference(tCreate).inMilliseconds;
      }
      BootTracer.mark('dir_guard.acquire.detail', {
        'rel': relativePath,
        'fs_warmup_wait_ms': fsWarmupMs,
        'lock_wait_ms': lockMs,
        'exists_ms': existsMs,
        'create_ms': createMs,
        'existed': exists,
        'total_ms': DateTime.now().difference(tBegin).inMilliseconds,
      });
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
    final docsPath = await _docsPath();
    final sep = Platform.pathSeparator;
    return '$docsPath$sep$rootSubdir$sep$relativePath';
  }
}
