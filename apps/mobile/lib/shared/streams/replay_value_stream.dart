import 'dart:async';

/// Broadcast stream that replays the most recent value (and last error) to
/// every new subscriber. Equivalent to RxDart's `BehaviorSubject` but with a
/// minimal surface and no extra dependency.
class ReplayValueStream<T> {
  ReplayValueStream._(this._controller, T initial)
      : _hasValue = true,
        _value = initial;

  factory ReplayValueStream.seeded(T initial) {
    final controller = StreamController<T>.broadcast();
    return ReplayValueStream<T>._(controller, initial);
  }

  final StreamController<T> _controller;
  bool _hasValue;
  T? _value;
  Object? _lastError;
  StackTrace? _lastStackTrace;
  bool _closed = false;

  bool get hasValue => _hasValue;
  T get value {
    if (!_hasValue) {
      throw StateError('ReplayValueStream has no value');
    }
    return _value as T;
  }

  bool get isClosed => _closed;

  /// Returns a new stream that delivers the cached value (if any) before any
  /// subsequent broadcast events. Safe under concurrent emission: the
  /// upstream subscription is established in onListen synchronously, so no
  /// events can be dropped between cache-emit and stream-forward.
  Stream<T> get stream {
    late StreamController<T> out;
    StreamSubscription<T>? sub;
    out = StreamController<T>(
      onListen: () {
        // Subscribe FIRST so any concurrent emissions are forwarded; then
        // emit the cached value. Both operations are synchronous, so no
        // events can be lost in between.
        sub = _controller.stream.listen(
          (data) {
            if (!out.isClosed) out.add(data);
          },
          onError: (Object e, StackTrace st) {
            if (!out.isClosed) out.addError(e, st);
          },
          onDone: () {
            if (!out.isClosed) out.close();
          },
        );
        if (_lastError != null && !out.isClosed) {
          out.addError(_lastError!, _lastStackTrace);
        }
        if (_hasValue && !out.isClosed) {
          out.add(_value as T);
        }
      },
      onCancel: () async {
        await sub?.cancel();
        sub = null;
      },
    );
    return out.stream;
  }

  void add(T data) {
    if (_closed) return;
    _value = data;
    _hasValue = true;
    _lastError = null;
    _lastStackTrace = null;
    _controller.add(data);
  }

  void addError(Object error, [StackTrace? stackTrace]) {
    if (_closed) return;
    _lastError = error;
    _lastStackTrace = stackTrace;
    _controller.addError(error, stackTrace);
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _controller.close();
  }
}
