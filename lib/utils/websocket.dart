import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// Long-lived WebSocket wrapper with an explicit state machine, single
/// in-flight connect, capped exponential-backoff reconnect, idle
/// watchdog, and deterministic disposal. Designed to be owned by an
/// autoDispose Riverpod provider so the connection follows the
/// screen lifecycle: when the provider tears down, [dispose] is
/// invoked and no further reconnects can race the teardown.
class WebSocketService {
  WebSocketService(
    this.url, {
    this.connectTimeout = const Duration(seconds: 10),
    this.initialReconnectDelay = const Duration(seconds: 2),
    this.maxReconnectDelay = const Duration(seconds: 30),
    this.maxReconnectAttempts = 8,
    this.idleTimeout = const Duration(seconds: 90),
    this.idleCheckInterval = const Duration(seconds: 30),
  }) {
    // Lazy connect: only dial when something starts listening to the
    // upstream data stream. This keeps providers cheap to construct
    // (e.g. Riverpod's eager factory chain) without opening sockets
    // until the data is actually needed.
    _controller.onListen = () {
      if (_disposed) return;
      if (_state == WebSocketConnectionState.disconnected ||
          _state == WebSocketConnectionState.error) {
        connect();
      }
    };
  }

  final Uri url;
  final Duration connectTimeout;
  final Duration initialReconnectDelay;
  final Duration maxReconnectDelay;
  final int maxReconnectAttempts;
  final Duration idleTimeout;
  final Duration idleCheckInterval;

  final StreamController<dynamic> _controller =
      StreamController<dynamic>.broadcast();
  final StreamController<WebSocketConnectionState> _stateController =
      StreamController<WebSocketConnectionState>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _channelSub;
  Future<void>? _connectFuture;
  Timer? _reconnectTimer;
  Timer? _idleTimer;

  WebSocketConnectionState _state = WebSocketConnectionState.disconnected;
  int _reconnectAttempt = 0;
  DateTime? _lastMessageAt;
  bool _disposed = false;
  bool _autoReconnect = true;

  Stream<dynamic> get stream => _controller.stream;

  Stream<WebSocketConnectionState> get states => _stateController.stream;

  WebSocketConnectionState get state => _state;

  bool get isConnected => _state == WebSocketConnectionState.connected;

  bool get isDisposed => _disposed;

  /// Open the connection. Concurrent calls are coalesced into a
  /// single in-flight attempt — this is the only public path that
  /// can transition into [WebSocketConnectionState.connecting].
  Future<void> connect() {
    if (_disposed) return Future.value();
    if (isConnected) return Future.value();
    final inflight = _connectFuture;
    if (inflight != null) return inflight;
    final future = _connectInternal();
    _connectFuture = future;
    return future.whenComplete(() {
      if (identical(_connectFuture, future)) _connectFuture = null;
    });
  }

  /// Ensure the connection is up. Returns true on success.
  /// Resets the reconnect-attempt counter when the caller is
  /// recovering from a terminal [WebSocketConnectionState.error] so
  /// the backoff budget starts fresh from an explicit user action.
  Future<bool> ensureConnected() async {
    if (_disposed) return false;
    if (isConnected) return true;
    if (_state == WebSocketConnectionState.error) {
      _reconnectAttempt = 0;
    }
    try {
      await connect();
    } catch (_) {
      // Swallow — state is the source of truth, errors are logged
      // inside _connectInternal and propagated via state transitions.
    }
    return isConnected;
  }

  /// Tear down and re-open the connection. Resets the backoff
  /// counter so the caller (typically a user-initiated retry) gets
  /// the full reconnect budget again.
  Future<void> forceReconnect() async {
    if (_disposed) return;
    _log('forceReconnect requested');
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempt = 0;
    await _teardownTransport();
    if (_disposed) return;
    _setState(WebSocketConnectionState.disconnected);
    await connect();
  }

  void send(dynamic data) {
    if (_disposed) return;
    if (isConnected) {
      _send(data);
      return;
    }
    _log('send while not connected — attempting to connect first');
    ensureConnected().then((connected) {
      if (_disposed) return;
      if (connected) {
        _send(data);
      } else {
        _log('send dropped — failed to connect');
      }
    });
  }

  /// Synchronous dispose: idempotent. Cancels timers, marks the
  /// service disposed (so any pending callback short-circuits), and
  /// fires off close requests. Close completions are not awaited
  /// because Riverpod's `onDispose` is synchronous; the WS sink
  /// drains asynchronously inside the engine.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _autoReconnect = false;
    _log('dispose');

    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _stopIdleWatch();

    // Fire-and-forget — _disposed=true above gates all callbacks.
    unawaited(_teardownTransport());

    _state = WebSocketConnectionState.disconnected;
    if (!_stateController.isClosed) {
      _stateController.add(WebSocketConnectionState.disconnected);
      unawaited(_stateController.close());
    }
    if (!_controller.isClosed) {
      unawaited(_controller.close());
    }
  }

  Future<void> _connectInternal() async {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    final attempt = _reconnectAttempt + 1;
    _setState(
      _reconnectAttempt == 0
          ? WebSocketConnectionState.connecting
          : WebSocketConnectionState.reconnecting,
    );
    _log('connect attempt=$attempt url=$url');

    // Always cancel/close any prior transport before opening a new one.
    await _teardownTransport();
    if (_disposed) return;

    WebSocketChannel? channel;
    try {
      channel = WebSocketChannel.connect(url);
      await channel.ready.timeout(
        connectTimeout,
        onTimeout: () {
          throw TimeoutException(
            'WebSocket handshake timed out after '
            '${connectTimeout.inSeconds}s',
          );
        },
      );

      if (_disposed) {
        unawaited(channel.sink.close(status.normalClosure));
        return;
      }

      _channel = channel;
      _channelSub = channel.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      _reconnectAttempt = 0;
      _lastMessageAt = DateTime.now();
      _startIdleWatch();
      _setState(WebSocketConnectionState.connected);
      _log('connected');
    } catch (e) {
      _log('connect failed: $e');
      // Best-effort close of the half-opened channel so we don't
      // leak the underlying socket.
      if (channel != null) {
        try {
          unawaited(channel.sink.close(status.normalClosure));
        } catch (_) {}
      }
      _channel = null;
      if (_disposed) return;
      _scheduleReconnect();
    }
  }

  void _onData(dynamic message) {
    if (_disposed) return;
    _lastMessageAt = DateTime.now();
    if (!_controller.isClosed) {
      _controller.add(message);
    }
  }

  void _onError(Object error, [StackTrace? stack]) {
    if (_disposed) return;
    _log('stream error: $error');
    _handleDrop(reason: 'error');
  }

  void _onDone() {
    if (_disposed) return;
    final code = _channel?.closeCode;
    final reason = _channel?.closeReason;
    _log('stream done (closeCode=$code, closeReason=$reason)');
    _handleDrop(reason: 'done');
  }

  void _handleDrop({required String reason}) {
    if (_disposed) return;
    _stopIdleWatch();
    // Synchronously detach the live transport. Any in-flight
    // _connectInternal sees _channel=null and short-circuits.
    final sub = _channelSub;
    _channelSub = null;
    if (sub != null) unawaited(sub.cancel());
    final ch = _channel;
    _channel = null;
    if (ch != null) {
      try {
        unawaited(ch.sink.close(status.normalClosure));
      } catch (_) {}
    }
    if (!_autoReconnect) {
      _setState(WebSocketConnectionState.disconnected);
      return;
    }
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed || !_autoReconnect) return;
    if (_reconnectTimer != null) return;

    if (_reconnectAttempt >= maxReconnectAttempts) {
      _log('giving up after $_reconnectAttempt failed attempts');
      _setState(WebSocketConnectionState.error);
      return;
    }

    _reconnectAttempt += 1;
    final delay = _backoffDelay(_reconnectAttempt);
    _setState(WebSocketConnectionState.reconnecting);
    _log(
      'scheduling reconnect attempt=$_reconnectAttempt '
      'delay=${delay.inMilliseconds}ms',
    );

    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      if (_disposed) return;
      // Fire-and-forget — connect() handles its own errors.
      unawaited(connect());
    });
  }

  Duration _backoffDelay(int attempt) {
    final baseMs = initialReconnectDelay.inMilliseconds;
    final maxMs = maxReconnectDelay.inMilliseconds;
    // Cap the shift so we don't overflow on absurd attempt counts —
    // shift past 20 is already minutes and would saturate maxMs.
    final shift = (attempt - 1).clamp(0, 20);
    final expMs = baseMs * (1 << shift);
    return Duration(milliseconds: expMs > maxMs ? maxMs : expMs);
  }

  void _startIdleWatch() {
    _stopIdleWatch();
    _idleTimer = Timer.periodic(idleCheckInterval, (timer) {
      if (_disposed || !isConnected) {
        timer.cancel();
        if (identical(_idleTimer, timer)) _idleTimer = null;
        return;
      }
      final last = _lastMessageAt;
      if (last != null &&
          DateTime.now().difference(last) > idleTimeout) {
        _log(
          'idle timeout exceeded (${idleTimeout.inSeconds}s) — '
          'forcing reconnect',
        );
        _handleDrop(reason: 'idle');
      }
    });
  }

  void _stopIdleWatch() {
    _idleTimer?.cancel();
    _idleTimer = null;
  }

  Future<void> _teardownTransport() async {
    final sub = _channelSub;
    _channelSub = null;
    if (sub != null) {
      try {
        await sub.cancel();
      } catch (_) {}
    }
    final ch = _channel;
    _channel = null;
    if (ch != null) {
      try {
        await ch.sink.close(status.normalClosure);
      } catch (_) {}
    }
  }

  void _send(dynamic data) {
    try {
      _channel?.sink.add(data);
    } catch (e) {
      _log('send error: $e');
      _handleDrop(reason: 'send-error');
    }
  }

  void _setState(WebSocketConnectionState next) {
    if (_state == next) return;
    _state = next;
    _log('state -> ${next.name}');
    if (!_stateController.isClosed) {
      _stateController.add(next);
    }
  }

  void _log(String msg) {
    if (kDebugMode) {
      debugPrint('[WS][${url.host}] $msg');
    }
  }
}
