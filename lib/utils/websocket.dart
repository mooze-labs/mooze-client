import 'dart:async';
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
    if (_isDisposed || _isConnected) return;

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
          debugPrint("WebSocket error: $error");
          _handleDisconnect();
          final completer = _connectionCompleter;
          if (completer != null && !completer.isCompleted) {
            completer.completeError(error);
          }
        },
        onDone: () {
          debugPrint("WebSocket connection closed");
          _handleDisconnect();
        },
        cancelOnError: false,
      );

      // Wait for the first message to confirm connection
      await _connectionCompleter?.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Connection timeout');
        },
      );

      // Start heartbeat to keep connection alive
      _startHeartbeat();
    } catch (e, stack) {
      debugPrint("WebSocket connection error: $e");
      debugPrint(stack.toString());
      _handleDisconnect();
      // Não propaga o erro para não travar o app
      // O sistema de reconexão automática vai tentar novamente
    } finally {
      _connectionCompleter = null;
    }
  }

  void _handleDisconnect() {
    _isConnected = false;
    _channel = null;
    _stopHeartbeat();

    if (!_isDisposed) {
      _attemptReconnect();
    }
  }

  void _startHeartbeat() {
    _stopHeartbeat();

    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isDisposed || !_isConnected) {
        timer.cancel();
        return;
      }

      // Verifica se não recebeu mensagens nos últimos 60 segundos
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
    if (_isDisposed || _reconnectTimer != null) return;

    _reconnectTimer = Timer(const Duration(seconds: 2), () {
      _reconnectTimer = null;
      if (!_isDisposed && !_isConnected) {
        _connect();
      }
    });
  }

  // Add method to check and ensure connection
  Future<bool> ensureConnected() async {
    if (_isDisposed) return false;
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
    if (_isDisposed) return;

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
