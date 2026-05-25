import 'dart:async';

import 'package:flutter/foundation.dart';

import 'secure_storage.dart';

/// Shared in-memory cache for the wallet mnemonic Keychain read.
///
/// Two boot-time consumers used to issue independent reads for the
/// same key (`mnemonic_mainWallet`):
///
///   1. `MnemonicProvider` / `KeyStoreImpl.getKey(...)` — used by the
///      splash screen routing decision.
///   2. `FlutterSecureCredentialStore.load()` — used by the V2 boot
///      orchestrator's `_runCredentialsPhase()`.
///
/// On a cold-start iOS Keychain (simulator or low-power device), each
/// read can take seconds. The user trace showed the first read costing
/// ~600 ms and the *second* read costing ~4 s — both reading the same
/// value. Centralising the read here:
///
///   * runs the platform-channel call exactly once;
///   * lets `main()` kick it off in parallel with `runApp`, so by the
///     time either consumer awaits it, the future may already be
///     resolved;
///   * deliberately holds the `Future` rather than the value, so
///     consumers can `await` safely whether the read is in flight or
///     done.
///
/// The cache is intentionally **process-wide**. It is invalidated by
/// `clear()` from the import-wallet flow and `DeleteWalletUseCase`,
/// the only call sites that can replace the underlying Keychain entry
/// at runtime.
class MnemonicPrefetch {
  MnemonicPrefetch._();

  static const String key = 'mnemonic_mainWallet';

  static Future<String?>? _future;
  static int? _startedAtMs;
  static int? _completedAtMs;

  /// Kick off the Keychain read if it hasn't already started. Safe to
  /// call multiple times — only the first call hits the platform
  /// channel; subsequent calls are no-ops. Returns the same future.
  static Future<String?> start() {
    final existing = _future;
    if (existing != null) return existing;
    final stopwatch = Stopwatch()..start();
    _startedAtMs = DateTime.now().millisecondsSinceEpoch;
    final f = SecureStorageProvider.instance.read(key: key).then(
      (value) {
        stopwatch.stop();
        _completedAtMs = DateTime.now().millisecondsSinceEpoch;
        if (kDebugMode) {
          debugPrint(
            '[MnemonicPrefetch] read completed in '
            '${stopwatch.elapsedMilliseconds}ms (hasValue=${value != null})',
          );
        }
        return value;
      },
      onError: (e, st) {
        stopwatch.stop();
        _completedAtMs = DateTime.now().millisecondsSinceEpoch;
        if (kDebugMode) {
          debugPrint(
            '[MnemonicPrefetch] read failed in '
            '${stopwatch.elapsedMilliseconds}ms: $e',
          );
        }
        Error.throwWithStackTrace(e, st as StackTrace);
      },
    );
    _future = f;
    return f;
  }

  /// Read the cached value. Triggers [start] lazily if no one has
  /// kicked off the prefetch yet.
  static Future<String?> get() {
    return _future ?? start();
  }

  /// Wall-clock duration from prefetch start to completion, in
  /// milliseconds. `null` until the read finishes. Used by the trace
  /// markers so we can compare boot timings before/after this change.
  static int? get durationMs {
    final s = _startedAtMs;
    final c = _completedAtMs;
    if (s == null || c == null) return null;
    return c - s;
  }

  /// Invalidate the cache. Called by import + delete-wallet flows so
  /// the next `get()` re-reads from disk.
  static void clear() {
    _future = null;
    _startedAtMs = null;
    _completedAtMs = null;
  }
}
