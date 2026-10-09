import 'events.dart';

Future<T> trackOperation<T>({
  required void Function(AnalyticsEvent) track,
  required Future<T> Function() run,
  required AnalyticsEvent started,
  required AnalyticsEvent Function(T) outcome,
  required AnalyticsEvent failed,
}) async {
  track(started);
  final T value;
  try {
    value = await run();
  } catch (_) {
    track(failed);
    rethrow;
  }
  track(outcome(value));
  return value;
}

class PixStatusTracker {
  PixStatusTracker({
    required bool Function() allowed,
    required void Function(AnalyticsEvent) track,
  }) : _allowed = allowed,
       _track = track;
  final bool Function() _allowed;
  final void Function(AnalyticsEvent) _track;
  // IDs are local deduplication keys only, never persisted or sent.
  final _previous = <String, String>{};
  void clear() => _previous.clear();
  void observe(String id, String rawStatus) {
    if (!_allowed()) {
      clear();
      return;
    }
    final status = _pixStatus(rawStatus);
    if (status == null) return;
    final old = _previous.remove(id);
    _previous[id] = status;
    if (_previous.length > 256) _previous.remove(_previous.keys.first);
    if (old != null && old != status) {
      _track(AnalyticsEvent('pix_deposit_status_changed', {'status': status}));
    }
  }
}

String? _pixStatus(String raw) {
  final value = raw.toLowerCase().replaceAll('_', '');
  if (value == 'pending') return 'pending';
  if ({
    'underreview',
    'processing',
    'fundsprepared',
    'depixsent',
    'paid',
    'broadcasted',
    'med',
    'processingrefund',
    'broadcastedrefund',
  }.contains(value)) {
    return 'processing';
  }
  if (value == 'finished' || value == 'completed') return 'completed';
  if (value == 'failed') return 'failed';
  if (value == 'expired' || value == 'timeout') return 'expired';
  if (value == 'refunded' || value == 'finishedrefund') return 'refunded';
  return null;
}
