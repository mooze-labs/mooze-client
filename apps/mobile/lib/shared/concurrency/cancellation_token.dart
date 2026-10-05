class CancellationException implements Exception {
  const CancellationException([this.reason]);
  final String? reason;
  @override
  String toString() => 'CancellationException(${reason ?? ''})';
}

class CancellationToken {
  bool _cancelled = false;
  final List<void Function()> _listeners = [];

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    final listeners = List<void Function()>.of(_listeners);
    _listeners.clear();
    for (final l in listeners) {
      try {
        l();
      } catch (_) {}
    }
  }

  void onCancel(void Function() callback) {
    if (_cancelled) {
      callback();
      return;
    }
    _listeners.add(callback);
  }

  void throwIfCancelled() {
    if (_cancelled) throw const CancellationException();
  }
}
