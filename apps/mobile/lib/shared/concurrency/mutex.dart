import 'dart:async';

/// FIFO mutex. Critical sections execute in the order their futures were chained.
///
/// Uses a "tail future" instead of a queue; each `protect` call awaits the previous
/// completer before running its body, then releases the next waiter via its own
/// completer. This avoids a separate scheduler.
class Mutex {
  Future<void>? _tail;

  bool get isLocked => _tail != null;

  Future<T> protect<T>(Future<T> Function() body) async {
    final previous = _tail;
    final completer = Completer<void>();
    _tail = completer.future;
    try {
      if (previous != null) {
        await previous;
      }
      return await body();
    } finally {
      completer.complete();
      if (identical(_tail, completer.future)) {
        _tail = null;
      }
    }
  }
}
