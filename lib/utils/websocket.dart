import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

/// Service to handle websocket connections using WebSocketChannel.
class WebSocketService {
  final Uri url;
  WebSocketChannel? _channel;
  final StreamController<dynamic> _controller =
      StreamController<dynamic>.broadcast();
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  bool _isConnected = false;
  bool _isDisposed = false;
  DateTime? _lastConnectAttempt;
  DateTime? _lastMessageReceived;
  Completer<void>? _connectionCompleter;
  int _reconnectAttempts = 0;
  static const int _maxReconnectDelay = 60;

  // Track connection state
  bool get isConnected => _isConnected && _channel != null;

  WebSocketService(this.url) {
    _controller.onListen = () {
      if (!_isConnected && !_isDisposed) {
        _connect();
      }
    };
  }

  Stream<dynamic> get stream => _controller.stream;

  Future<void> _connect() async {
    if (_isDisposed) {
      debugPrint('[WebSocket] Service disposed, aborting connection');
      return;
    }

    if (_isConnected) return;

    // Prevent connection attempts too close together
    final now = DateTime.now();
    if (_lastConnectAttempt != null &&
        now.difference(_lastConnectAttempt!).inSeconds < 2) {
      return;
    }

    _lastConnectAttempt = now;
    _connectionCompleter = Completer<void>();

    try {
      debugPrint("Connecting to ${url.toString()}");

      _channel = WebSocketChannel.connect(url);

      _channel!.stream.listen(
        (message) {
          if (_isDisposed) return;

          _isConnected = true;
          _lastMessageReceived = DateTime.now();
          if (!_isDisposed && !_controller.isClosed) {
            _controller.add(message);
          }
          final completer = _connectionCompleter;
          if (completer != null && !completer.isCompleted) {
            completer.complete();
          }
        },
        onError: (error) {
          if (_isDisposed) return;

          debugPrint("WebSocket stream error: $error");
          final shouldRetry = _handleConnectionError(error);
          _handleDisconnect(shouldRetry: shouldRetry);
          final completer = _connectionCompleter;
          if (completer != null && !completer.isCompleted) {
            completer.completeError(error);
          }
        },
        onDone: () {
          if (_isDisposed) return;

          debugPrint("WebSocket connection closed");
          _handleDisconnect();
        },
        cancelOnError: false,
      );

      // Wait for the first message to confirm connection
      await _connectionCompleter?.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (_isDisposed) {
            throw Exception('Service disposed during connection');
          }
          throw TimeoutException('Connection timeout');
        },
      );

      _reconnectAttempts = 0;

      // Start heartbeat to keep connection alive
      if (!_isDisposed) {
        _startHeartbeat();
      }
    } catch (e, stack) {
      if (_isDisposed) {
        debugPrint('[WebSocket] Connection aborted - service disposed');
        return;
      }

      final shouldRetry = _handleConnectionError(e);
      debugPrint("WebSocket connection error: $e (willRetry: $shouldRetry)");

      if (kDebugMode) {
        debugPrint(stack.toString());
      }

      _handleDisconnect(shouldRetry: shouldRetry);
    } finally {
      _connectionCompleter = null;
    }
  }

  void _handleDisconnect({bool shouldRetry = true}) {
    _isConnected = false;
    _channel = null;
    _stopHeartbeat();

    _connectionCompleter?.completeError('Disconnected');
    _connectionCompleter = null;

    if (!_isDisposed && shouldRetry) {
      _attemptReconnect();
    } else if (!shouldRetry) {
      debugPrint('[WebSocket] Não tentando reconectar devido ao tipo de erro');
      _reconnectAttempts = 0;
    }
  }

  bool _handleConnectionError(dynamic error) {
    if (error is SocketException) {
      final errno = error.osError?.errorCode;

      if (errno == 8 || // nodename nor servname provided
          errno == 35 || // Resource temporarily unavailable
          errno == 61 || // Connection refused
          errno == 64 || // Host is down
          errno == 65) {
        // No route to host
        debugPrint('[WebSocket] Erro de rede temporário (errno: $errno)');
        return true;
      }
    }

    if (error is TimeoutException) {
      debugPrint('[WebSocket] Timeout - erro temporário');
      return true;
    }

    if (error.toString().contains('WebSocketChannelException')) {
      debugPrint('[WebSocket] WebSocketChannelException - erro temporário');
      return true;
    }

    return true;
  }

  void _startHeartbeat() {
    _stopHeartbeat();

    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isDisposed || !_isConnected) {
        timer.cancel();
        return;
      }

      if (_lastMessageReceived != null &&
          DateTime.now().difference(_lastMessageReceived!).inSeconds > 60) {
        debugPrint("WebSocket sem resposta há muito tempo, reconectando...");
        _handleDisconnect();
        return;
      }
    });
  }

  void _stopHeartbeat() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void _attemptReconnect() {
    if (_isDisposed) {
      debugPrint('[WebSocket] Service disposed, skipping reconnect');
      return;
    }

    if (_reconnectTimer != null) return;

    _reconnectAttempts++;

    final delaySeconds = (2 * (1 << (_reconnectAttempts - 1).clamp(0, 5)))
        .clamp(2, _maxReconnectDelay);

    debugPrint(
      '[WebSocket] Tentando reconectar em ${delaySeconds}s (tentativa $_reconnectAttempts)',
    );

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      _reconnectTimer = null;
      if (!_isDisposed && !_isConnected) {
        _connect();
      }
    });
  }

  // Add method to check and ensure connection
  Future<bool> ensureConnected() async {
    if (_isDisposed) {
      debugPrint('[WebSocket] Service disposed, cannot connect');
      return false;
    }

    if (_isConnected && _channel != null) return true;

    try {
      await _connect();
      return true;
    } catch (e) {
      debugPrint("Failed to ensure connection: $e");
      return false;
    }
  }

  Future<void> forceReconnect() async {
    if (_isDisposed) {
      debugPrint('[WebSocket] Service disposed, skipping force reconnect');
      return;
    }

    debugPrint("[WebSocket] Forcing reconnection...");

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    _isConnected = false;
    try {
      if (_channel != null) {
        await _channel!.sink.close(status.normalClosure);
      }
    } catch (e) {
      debugPrint(
        "[WebSocket] Error closing channel during force reconnect: $e",
      );
    }
    _channel = null;

    await Future.delayed(const Duration(milliseconds: 500));

    if (!_isDisposed) {
      await _connect();
    }
  }

  void send(dynamic data) {
    if (_isDisposed) return;

    if (!_isConnected) {
      debugPrint("WebSocket not connected, attempting to connect...");
      ensureConnected().then((connected) {
        if (connected) {
          _sendData(data);
        } else {
          debugPrint("Failed to connect, message not sent");
        }
      });
    } else {
      _sendData(data);
    }
  }

  void _sendData(dynamic data) {
    try {
      _channel?.sink.add(data);
    } catch (e) {
      debugPrint("Error sending WebSocket data: $e");
      _handleDisconnect();
    }
  }

  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    _stopHeartbeat();

    try {
      if (_channel != null) {
        _channel!.sink.close(status.normalClosure);
      }
    } catch (e) {
      debugPrint("Error closing WebSocket channel: $e");
    }

    try {
      if (!_controller.isClosed) {
        _controller.close();
      }
    } catch (e) {
      debugPrint("Error closing controller: $e");
    }
  }
}
