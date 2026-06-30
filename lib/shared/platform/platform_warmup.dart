import 'dart:async';
import 'dart:io';

import 'package:flutter_breez_liquid/flutter_breez_liquid.dart' as breez;
import 'package:lwk/lwk.dart';
import 'package:path_provider/path_provider.dart';

import '../diagnostics/boot_tracer.dart';

/// Process-wide cache for the Rust FFI library initializations.
///
/// The V2 boot's `PlatformInitializerImpl` calls `LibLwk.init()` and
/// `FlutterBreezLiquid.init()` sequentially during the `platform`
/// phase — each one performs `flutter_rust_bridge` codegen
/// registration plus loading of the Rust dynamic library. Profiled
/// boots on the iOS simulator showed the two combined taking ~900 ms
/// of UI-thread blocking work, surfacing as a JANK of >1 s right
/// before the splash screen could route.
///
/// This helper warms both inits up from `main()` — they fire in
/// parallel with the mnemonic prefetch and the `SharedPreferences`
/// load that already happen there. By the time the boot orchestrator
/// reaches the `platform` phase, the inits are usually finished, so
/// awaiting them is a no-op.
///
/// `flutter_rust_bridge` will throw "Bad state: Should not initialize
/// flutter_rust_bridge twice" if `init()` is called twice — the cache
/// keeps both calls referring to a single Future, satisfying that
/// invariant while exposing the same await semantics to consumers.
class PlatformWarmup {
  PlatformWarmup._();

  static Future<void>? _lwkFuture;
  static Future<void>? _breezFuture;
  static Future<void>? _fsFuture;
  static int? _lwkMs;
  static int? _breezMs;
  static int? _fsMs;

  /// Kicks the FFI inits AND the filesystem warmup off without
  /// awaiting. Safe to call multiple times — subsequent calls reuse
  /// the in-flight or completed Futures. Call from `main()` right
  /// after `WidgetsFlutterBinding.ensureInitialized()` to overlap
  /// with the rest of the startup pipeline.
  ///
  /// FS warmup rationale: on iOS, the first `Directory.exists()` (or
  /// any read against the `NSDocumentDirectory` sandbox) can block
  /// for several seconds while data-protection unlock + FS metadata
  /// cache prime. Profiled traces showed three parallel
  /// `dir_guard.acquire` calls all returning around the same
  /// ~4.5 s mark — symptom of OS-level serialisation. Touching the
  /// docs root once from `main()` eats that cost in parallel with
  /// the splash render so the wallet-directory acquires that run
  /// later in boot are sub-millisecond.
  static void start() {
    _lwkFuture ??= _runLwkInit();
    _breezFuture ??= _runBreezInit();
    _fsFuture ??= _runFsWarmup();
  }

  /// Awaits FFI initializations only. The FS warmup is intentionally
  /// fire-and-forget — keeping it out of the await set means the V2
  /// boot's `platform` phase remains a near-no-op (~2 ms) and the
  /// `WalletDirectoryGuardImpl.acquire()` calls that fire later see
  /// the unlocked sandbox without explicitly waiting on us.
  static Future<void> awaitAll() async {
    start();
    await Future.wait([_lwkFuture!, _breezFuture!]);
  }

  /// Awaits the filesystem warmup specifically. Callers that are
  /// about to touch the documents sandbox can opt into the cost
  /// (still useful: by the time they call, the warmup is usually
  /// already done so this is a no-op).
  static Future<void> awaitFs() {
    start();
    return _fsFuture!;
  }

  /// Wall-clock time the LWK FFI init took, in ms. Null until the
  /// future resolves. Exposed only for diagnostics / trace reports.
  static int? get lwkInitMs => _lwkMs;
  static int? get breezInitMs => _breezMs;
  static int? get fsWarmupMs => _fsMs;

  static Future<void> _runLwkInit() async {
    final t0 = DateTime.now();
    BootTracer.mark('platform_warmup.lwk.begin');
    await LibLwk.init();
    _lwkMs = DateTime.now().difference(t0).inMilliseconds;
    BootTracer.mark('platform_warmup.lwk.end', {'dur_ms': _lwkMs});
  }

  static Future<void> _runBreezInit() async {
    final t0 = DateTime.now();
    BootTracer.mark('platform_warmup.breez.begin');
    await breez.FlutterBreezLiquid.init();
    _breezMs = DateTime.now().difference(t0).inMilliseconds;
    BootTracer.mark('platform_warmup.breez.end', {'dur_ms': _breezMs});
  }

  static Future<void> _runFsWarmup() async {
    final t0 = DateTime.now();
    BootTracer.mark('platform_warmup.fs.begin');
    try {
      final docs = await getApplicationDocumentsDirectory();
      // A single `exists()` on the docs root is enough to force iOS
      // to unlock the data-protection sandbox + populate the FS
      // metadata cache for that branch of the tree. Subsequent
      // `Directory.exists()` calls on subpaths return in single-digit
      // ms instead of seconds.
      await Directory(docs.path).exists();
    } catch (_) {
      // Non-fatal — the worst case is we lose the warmup benefit
      // and dir_acquire pays the cost itself.
    }
    _fsMs = DateTime.now().difference(t0).inMilliseconds;
    BootTracer.mark('platform_warmup.fs.end', {'dur_ms': _fsMs});
  }
}
