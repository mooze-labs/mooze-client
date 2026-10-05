import 'package:flutter/foundation.dart';
import 'package:no_screenshot/no_screenshot.dart';

/// Centralized, reference-counted controller for OS-level screenshot/screen-
/// recording protection (Android `FLAG_SECURE`, iOS secure-layer).
///
/// WHY this exists: the underlying `no_screenshot` plugin toggles a single
/// process-wide flag on the host Activity/Window — there is no per-route
/// scoping at the OS level, and it *persists* the secure state, re-applying it
/// on Activity re-attach. Calling `screenshotOff()/screenshotOn()` ad-hoc from
/// individual screens leaks that global flag across the whole app whenever an
/// exit path is missed (forward `push`, `pushReplacement`, `go`, `popUntil`,
/// deep links — none of which fire a back-only `PopScope`).
///
/// The fix is to treat protection as a *counted resource*: every visible
/// sensitive screen holds one claim. The OS flag is enabled when the first
/// claim is taken (0 → 1) and disabled only when the last claim is released
/// (1 → 0). This is correct under overlapping secure screens, double pushes,
/// and rapid navigation.
///
/// All plugin calls are funneled through a single serialized queue so the
/// async native round-trips can never interleave and land the OS in a state
/// that disagrees with the counter.
///
/// This is the ONLY place in the app allowed to call the `no_screenshot`
/// plugin. Screens opt in by wrapping themselves in `SecureScreen`.
class ScreenSecurityController {
  ScreenSecurityController._();

  /// Process-wide singleton. The OS flag it guards is itself process-wide, so
  /// a single shared counter is the correct model.
  static final ScreenSecurityController instance = ScreenSecurityController._();

  final NoScreenshot _noScreenshot = NoScreenshot.instance;

  /// Number of currently-visible secure screens. Protection is ON iff > 0.
  int _refCount = 0;

  /// Serializes native plugin calls. Each enable/disable/reset appends to this
  /// chain so a rapid enable→disable can't race into an inconsistent OS state.
  Future<void> _queue = Future<void>.value();

  /// Current number of active protection claims (exposed for tests/diagnostics).
  int get activeCount => _refCount;

  /// Whether OS-level protection should currently be active.
  bool get isProtected => _refCount > 0;

  /// Take a protection claim. Enables the OS flag on the first claim (0 → 1);
  /// subsequent claims only bump the counter. Idempotent at the OS level.
  Future<void> enable() {
    final wasUnprotected = _refCount == 0;
    _refCount++;
    _log('ENABLED');
    if (wasUnprotected) {
      // screenshotOff() == "screenshots off" == protection ON (FLAG_SECURE set).
      return _enqueue(() => _noScreenshot.screenshotOff());
    }
    return Future<void>.value();
  }

  /// Release a protection claim. Disables the OS flag only when the last claim
  /// is released (1 → 0). An unbalanced release at zero is a no-op (defensive:
  /// the counter never goes negative and protection stays correctly off).
  Future<void> disable() {
    if (_refCount == 0) {
      _log('DISABLE_IGNORED_AT_ZERO');
      return Future<void>.value();
    }
    _refCount--;
    _log('DISABLED');
    if (_refCount == 0) {
      // screenshotOn() == "screenshots on" == protection OFF (FLAG_SECURE clear).
      return _enqueue(() => _noScreenshot.screenshotOn());
    }
    return Future<void>.value();
  }

  /// App-startup / hot-restart safety reset. Forces the counter to zero and
  /// clears any stale persisted `FLAG_SECURE` left by a previously leaked
  /// session (the plugin re-applies persisted state on Activity attach). Call
  /// this once early in `main()`.
  Future<void> reset() {
    _refCount = 0;
    _log('RESET');
    return _enqueue(() => _noScreenshot.screenshotOn());
  }

  Future<void> _enqueue(Future<bool> Function() op) {
    _queue = _queue.then((_) async {
      try {
        await op();
      } catch (e) {
        // A failed native call must not break the chain or crash navigation;
        // the worst case is the OS flag lagging the counter by one transition.
        debugPrint('[ScreenSecurity] plugin call failed: $e');
      }
    });
    return _queue;
  }

  void _log(String transition) {
    debugPrint('[ScreenSecurity] $transition (count: $_refCount)');
  }
}
