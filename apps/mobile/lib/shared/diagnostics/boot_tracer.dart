import 'dart:async';
import 'package:flutter/foundation.dart';

/// Master switch. Flip to `false` to silence every tracer call in one
/// place — leave the `BootTracer.mark(...)` sprinkles in production
/// code paths since they compile down to a `static const` check.
const bool kBootTraceEnabled = true;

/// Diagnostic helper for finding UI-thread freezes during app boot.
///
/// Two outputs:
///
/// 1. **Heartbeat** — `Timer.periodic(100 ms)` running on the UI
///    isolate prints `[HB #N +Tms Δms]` every tick. Because the timer
///    can only fire when the main isolate is free, any `Δ` larger
///    than the expected 100 ms means the UI thread was blocked for
///    `Δ - 100` ms before that tick. Lines with `Δ > 200 ms` get a
///    `JANK` tag so they stand out in the log.
///
/// 2. **Marks** — `BootTracer.mark('label')` prints
///    `[MARK +Tms label]` synchronously where called. Drop these at
///    boot waypoints (start, lifecycle, PIN entered, first stream
///    emission, before/after heavy compute) and the relative
///    positions vs. the heartbeats locate which phase blocks.
///
/// All output goes through `debugPrint`, which Flutter throttles in
/// debug and elides in release; safe to leave wired.
class BootTracer {
  BootTracer._();

  static final Stopwatch _stopwatch = Stopwatch();
  static Timer? _timer;
  static int _lastTickMs = 0;
  static int _seq = 0;

  /// Begin the periodic heartbeat. Idempotent — calling twice is a
  /// no-op (avoids double-timers when the app rebuilds the widget
  /// tree during hot-reload).
  static void start() {
    if (!kBootTraceEnabled) return;
    if (_stopwatch.isRunning) return;
    _stopwatch.start();
    _lastTickMs = 0;
    _seq = 0;
    mark('tracer.start');
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final now = _stopwatch.elapsedMilliseconds;
      final delta = now - _lastTickMs;
      _lastTickMs = now;
      _seq += 1;
      final tag = delta > 200 ? 'JANK ' : '';
      debugPrint('[HB $tag#$_seq +${now}ms Δ${delta}ms]');
    });
  }

  /// Stamp a milestone. Cheap and synchronous so it can sit on the
  /// hot path without adding measurable cost.
  static void mark(String label, [Map<String, Object?>? extra]) {
    if (!kBootTraceEnabled) return;
    final ms = _stopwatch.elapsedMilliseconds;
    final extraStr = (extra == null || extra.isEmpty)
        ? ''
        : ' ${extra.entries.map((e) => '${e.key}=${e.value}').join(' ')}';
    debugPrint('[MARK +${ms}ms $label$extraStr]');
  }

  /// Convenience: measure the wall-clock cost of a synchronous block.
  /// Logs `before` immediately and `after Δ=Nms` when the block
  /// returns. Useful for wrapping things like `compute()` calls.
  static Future<T> measureAsync<T>(
    String label,
    Future<T> Function() body,
  ) async {
    if (!kBootTraceEnabled) return body();
    mark('$label.before');
    final start = _stopwatch.elapsedMilliseconds;
    try {
      final result = await body();
      final delta = _stopwatch.elapsedMilliseconds - start;
      mark('$label.after', {'Δ': '${delta}ms'});
      return result;
    } catch (e) {
      final delta = _stopwatch.elapsedMilliseconds - start;
      mark('$label.threw', {'Δ': '${delta}ms', 'err': '$e'});
      rethrow;
    }
  }

  /// Stop the heartbeat. Normally unused — let it run for the lifetime
  /// of the app while diagnosing.
  static void stop() {
    _timer?.cancel();
    _timer = null;
    _stopwatch.stop();
  }
}
