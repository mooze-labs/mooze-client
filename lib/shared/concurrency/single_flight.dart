import 'dart:async';

/// De-duplicates concurrent calls keyed by [K]. While a call for a given key
/// is in flight, additional calls with the same key receive the same future
/// instead of starting new work.
///
/// Implementation note: this version forwards body's outcome through a
/// [Completer]. We deliberately avoid `Future.whenComplete` because that API
/// awaits the action's return value if it is a Future — and an expression
/// lambda like `() => _inflight.remove(key)` returns the just-removed Future
/// (which IS the wrapped future), causing a self-await deadlock that is
/// almost impossible to spot by inspection.
class SingleFlight<K, V> {
  final Map<K, Future<V>> _inflight = {};

  Future<V> run(K key, Future<V> Function() body) {
    final existing = _inflight[key];
    if (existing != null) return existing;
    final completer = Completer<V>();
    final wrapped = completer.future;
    _inflight[key] = wrapped;
    // Kick off the body and forward its outcome. We never await body here;
    // we just listen for completion to settle the completer.
    body().then((value) {
      _inflight.remove(key);
      if (!completer.isCompleted) completer.complete(value);
    }, onError: (Object e, StackTrace st) {
      _inflight.remove(key);
      if (!completer.isCompleted) completer.completeError(e, st);
    });
    return wrapped;
  }

  bool isInflight(K key) => _inflight.containsKey(key);
}
