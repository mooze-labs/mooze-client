import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:mooze_mobile/services/app_logger_service.dart';

import '../../domain/entities/peg.dart';
import '../../domain/usecases/peg_tracker.dart';
import '../mappers/core_swap_mapper.dart';
import '../services/core_sideswap_session.dart';

/// [PegTracker] backed by mooze-core.
///
/// The core tracker polls SideSwap and persists terminal pegs. This class
/// owns the timer: it calls `pegRefreshDue` and arms a one-shot [Timer] at
/// the returned `nextWakeupMs`. No wakeup means nothing to poll, and the
/// timer stays off until [track] or [restore] adds a peg.
class CorePegTracker implements PegTracker {
  CorePegTracker({
    required CoreSideswapSession session,
    required Future<String> walletId,
    DateTime Function()? now,
    this.retryDelay = const Duration(seconds: 30),
  })  : _session = session,
        _walletId = walletId,
        _now = now ?? DateTime.now;

  static const _tag = 'PegTracker';
  final _log = AppLoggerService();

  final CoreSideswapSession _session;
  final Future<String> _walletId;
  final DateTime Function() _now;

  /// Delay before the next refresh after a failed one.
  final Duration retryDelay;

  final _controller = StreamController<List<TrackedPeg>>.broadcast();
  List<TrackedPeg> _current = const [];
  Timer? _timer;
  Future<void>? _refreshing;
  bool _disposed = false;

  @override
  Stream<List<TrackedPeg>> get pegs => _controller.stream;

  @override
  List<TrackedPeg> get current => List.unmodifiable(_current);

  /// True while a refresh is scheduled.
  @visibleForTesting
  bool get hasScheduledRefresh => _timer?.isActive ?? false;

  @override
  Future<void> restore() async {
    if (_disposed) return;
    final core = await _session.core;
    final restored = await core.pegRestore(walletId: await _walletId);
    if (_disposed) return;
    _publish(restored.map(trackedPegFromDto).toList(growable: false));
    await refresh();
  }

  @override
  void track(TrackedPeg peg) {
    if (_disposed) return;
    // The core already tracks the peg after `pegExecute`. Show it at once
    // and poll now: a peg-out deposit is usually on the wire already.
    if (_current.every((p) => p.orderId != peg.orderId)) {
      _publish([..._current, peg]);
    }
    unawaited(refresh());
  }

  @override
  void untrack(String orderId) {
    if (_disposed) return;
    _publish(_current.where((p) => p.orderId != orderId).toList());
    unawaited(
      _session.core
          .then((core) => core.pegUntrack(orderId: orderId))
          .catchError((Object _) {}),
    );
  }

  /// Polls the due pegs once and schedules the next poll. Concurrent calls
  /// share one refresh.
  Future<void> refresh() {
    if (_disposed) return Future.value();
    return _refreshing ??= _refresh().whenComplete(() => _refreshing = null);
  }

  Future<void> _refresh() async {
    _timer?.cancel();
    _timer = null;
    try {
      final core = await _session.connected();
      final result = await core.pegRefreshDue(walletId: await _walletId);
      if (_disposed) return;
      _publish(result.pegs.map(trackedPegFromDto).toList(growable: false));
      // `finished` lists each peg once, in the refresh where it ended.
      for (final peg in result.finished.map(trackedPegFromDto)) {
        if (peg.phase == PegPhase.insufficientAmount) _logBelowMinimum(peg);
      }
      final next = result.nextWakeupMs;
      if (next != null) {
        final delayMs = next.toInt() - _now().millisecondsSinceEpoch;
        _schedule(Duration(milliseconds: delayMs < 0 ? 0 : delayMs));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[CorePegTracker] refresh failed: $e');
      if (!_disposed && _current.any((p) => !p.isTerminal)) {
        _schedule(retryDelay);
      }
    }
  }

  /// Logs a peg whose deposit SideSwap did not take: below its minimum.
  ///
  /// The core never sends below the minimum it reads, so this means the
  /// minimum moved or the deposit shrank. A peg-in is lost: SideSwap has no
  /// return for BTC. A peg-out comes back, minus the network fee, to the
  /// return address that the core registered before the deposit.
  void _logBelowMinimum(TrackedPeg peg) {
    final id = peg.orderId;
    final amount = peg.amountSat;
    if (peg.direction == PegDirection.pegIn) {
      _log.error(
        _tag,
        'Peg-in $id ended below the SideSwap minimum ($amount sats): '
        'SideSwap has no return for BTC, the deposit is lost',
      );
    } else {
      _log.warning(
        _tag,
        'Peg-out $id ended below the SideSwap minimum ($amount sats): '
        'SideSwap returns the L-BTC to the return address of the order',
      );
    }
  }

  void _schedule(Duration delay) {
    if (_disposed) return;
    _timer?.cancel();
    _timer = Timer(delay, () => unawaited(refresh()));
  }

  void _publish(List<TrackedPeg> pegs) {
    _current = pegs;
    if (_disposed || _controller.isClosed) return;
    _controller.add(current);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _controller.close();
  }
}
