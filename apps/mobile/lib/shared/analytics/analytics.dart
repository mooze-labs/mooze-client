import 'dart:async';
import 'package:flutter/foundation.dart';
import 'events.dart';

abstract interface class ConsentStore {
  bool read();
  Future<void> write(bool enabled);
}

abstract interface class AnalyticsSink {
  Future<void> capture(AnalyticsEvent event);
  Future<void> stop();
}

/// Owns consent; SDK dependencies stay behind the injected sink.
class AnalyticsController extends ChangeNotifier {
  AnalyticsController({
    required this.configured,
    required ConsentStore store,
    required Future<AnalyticsSink> Function(bool Function()) load,
  }) : _store = store,
       _load = load {
    try {
      _enabled = configured && store.read();
    } catch (_) {
      _enabled = false;
    }
    _requested = _enabled;
  }
  final bool configured;
  final ConsentStore _store;
  final Future<AnalyticsSink> Function(bool Function()) _load;
  AnalyticsSink? _sink;
  bool _enabled = false;
  bool _requested = false;
  bool _started = false;
  bool _busy = false;
  bool _error = false;
  int _revision = 0;
  Future<void> _transition = Future.value();
  bool get enabled => _enabled;
  bool get busy => _busy;
  bool get error => _error;

  Future<void> start() {
    if (!_started) {
      _started = true;
      if (_enabled) return _reconcile();
    }
    return _transition;
  }

  Future<bool> setEnabled(bool value) async {
    if (value && !configured) return false;
    _requested = value;
    // Revocation closes the gate synchronously, even during SDK startup.
    if (!value) _enabled = false;
    await _reconcile(persist: value);
    return !_error;
  }

  Future<void> _reconcile({bool? persist}) {
    final revision = ++_revision;
    _busy = true;
    _error = false;
    notifyListeners();
    _transition = _transition
        .then((_) async {
          // Serialize storage too: an older opt-in must not overwrite a newer opt-out.
          if (persist != null) await _store.write(persist);
          if (revision != _revision) return;
          if (_sink != null) {
            await _sink!.stop();
            _sink = null;
          }
          _enabled = _requested;
          if (!_enabled) return;
          bool allowed() => _enabled && _requested && revision == _revision;
          final sink = await _load(allowed);
          if (allowed()) {
            _sink = sink;
          } else {
            await sink.stop();
          }
        })
        .catchError((Object _) {
          if (revision == _revision) {
            _enabled = false;
            _error = true;
          }
        })
        .whenComplete(() {
          if (revision == _revision) {
            _busy = false;
            notifyListeners();
          }
        });
    return _transition;
  }

  void track(AnalyticsEvent event) {
    if (!_enabled || !_requested || _sink == null) return;
    final safe = sanitizeEvent(event.name, event.properties);
    if (safe == null) return;
    // Do not await telemetry on the wallet's action path, or retain pre-consent events.
    try {
      unawaited(_sink!.capture(safe).catchError((Object _) {}));
    } catch (_) {
      /* fail open for wallet operations */
    }
  }
}
