import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';

/// Sync operation result
sealed class SyncResult<T> {}

class SyncSuccess<T> extends SyncResult<T> {
  final T data;
  final DateTime timestamp;

  SyncSuccess(this.data, this.timestamp);
}

class SyncError<T> extends SyncResult<T> {
  final String message;
  final String? stackTrace;

  SyncError(this.message, [this.stackTrace]);
}

/// Service to execute sync operations in isolates
///
/// This service allows executing heavy operations like blockchain sync
/// in separate isolates, avoiding blocking the main thread.
class IsolateSyncService {
  /// Executes a function in a separate isolate
  ///
  /// [function] - The function to execute (must be a top-level or static function)
  /// [args] - Arguments for the function
  ///
  /// Returns a [SyncResult] with the result or error
  static Future<SyncResult<R>> runInIsolate<T, R>(
    R Function(T) function,
    T args,
  ) async {
    try {
      final result = await Isolate.run(() => function(args));
      return SyncSuccess(result, DateTime.now());
    } catch (e, stack) {
      debugPrint('[IsolateSyncService] Isolate error: $e');
      return SyncError(e.toString(), stack.toString());
    }
  }

  /// Executes an asynchronous function in a separate isolate
  static Future<SyncResult<R>> runAsyncInIsolate<T, R>(
    Future<R> Function(T) function,
    T args,
  ) async {
    try {
      final result = await Isolate.run(() => function(args));
      return SyncSuccess(result, DateTime.now());
    } catch (e, stack) {
      debugPrint('[IsolateSyncService] Async isolate error: $e');
      return SyncError(e.toString(), stack.toString());
    }
  }

  /// Executes multiple operations in parallel using isolates
  static Future<List<SyncResult<R>>> runParallel<T, R>(
    List<(Future<R> Function(T), T)> operations,
  ) async {
    final futures = operations.map((op) => runAsyncInIsolate(op.$1, op.$2));
    return Future.wait(futures);
  }
}

/// Class to execute sync with automatic retry
class SyncWithRetry {
  final int maxRetries;
  final Duration retryDelay;
  final Duration Function(int attempt)? delayCalculator;

  const SyncWithRetry({
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
    this.delayCalculator,
  });

  /// Calculates delay for a specific attempt (exponential backoff)
  Duration _getDelay(int attempt) {
    if (delayCalculator != null) {
      return delayCalculator!(attempt);
    }
    // Exponential backoff: 2s, 4s, 8s, ...
    return retryDelay * (1 << (attempt - 1));
  }

  /// Executes an operation with automatic retry
  Future<SyncResult<T>> execute<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    int attempt = 0;
    String? lastError;

    while (attempt < maxRetries) {
      attempt++;

      try {
        debugPrint(
          '[SyncWithRetry] ${operationName ?? 'Operation'} attempt $attempt/$maxRetries',
        );

        final result = await operation();

        debugPrint(
          '[SyncWithRetry] ${operationName ?? 'Operation'} sucesso na tentativa $attempt',
        );
        return SyncSuccess(result, DateTime.now());
      } catch (e) {
        lastError = e.toString();
        debugPrint(
          '[SyncWithRetry] ${operationName ?? 'Operation'} falhou: $e',
        );

        if (attempt < maxRetries) {
          final delay = _getDelay(attempt);
          debugPrint(
            '[SyncWithRetry] Aguardando ${delay.inSeconds}s antes de retry...',
          );
          await Future.delayed(delay);
        }
      }
    }

    return SyncError('Failed after $maxRetries attempts: $lastError');
  }
}

/// Class to manage periodic sync
class PeriodicSyncManager {
  Timer? _timer;
  bool _isSyncing = false;
  final Duration interval;
  final Future<void> Function() syncOperation;
  final void Function(String error)? onError;

  PeriodicSyncManager({
    required this.interval,
    required this.syncOperation,
    this.onError,
  });

  bool get isRunning => _timer != null;
  bool get isSyncing => _isSyncing;

  /// Starts periodic sync
  void start({bool syncImmediately = true}) {
    if (isRunning) {
      debugPrint('[PeriodicSyncManager] Already running, ignoring start');
      return;
    }

    debugPrint(
      '[PeriodicSyncManager] Starting periodic sync (${interval.inSeconds}s)',
    );

    if (syncImmediately) {
      _performSync();
    }

    _timer = Timer.periodic(interval, (_) => _performSync());
  }

  /// Stops periodic sync
  void stop() {
    debugPrint('[PeriodicSyncManager] Stopping periodic sync');
    _timer?.cancel();
    _timer = null;
  }

  /// Forces an immediate execution
  Future<void> syncNow() async {
    await _performSync();
  }

  Future<void> _performSync() async {
    if (_isSyncing) {
      debugPrint('[PeriodicSyncManager] Sync already in progress, skipping');
      return;
    }

    _isSyncing = true;
    try {
      await syncOperation();
    } catch (e) {
      debugPrint('[PeriodicSyncManager] Sync error: $e');
      onError?.call(e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  void dispose() {
    stop();
  }
}

/// Arguments for Liquid sync in isolate
class LiquidSyncIsolateArgs {
  final String electrumUrl;
  final bool validateDomain;
  final String networkName;
  final String descriptor;
  final String dbPath;

  const LiquidSyncIsolateArgs({
    required this.electrumUrl,
    required this.validateDomain,
    required this.networkName,
    required this.descriptor,
    required this.dbPath,
  });
}

/// Arguments for BDK sync in isolate
class BdkSyncIsolateArgs {
  final String electrsUrl;
  final String networkName;
  final String mnemonic;

  const BdkSyncIsolateArgs({
    required this.electrsUrl,
    required this.networkName,
    required this.mnemonic,
  });
}
