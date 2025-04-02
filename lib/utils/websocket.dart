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
  bool _isConnected = false;
  bool _isDisposed = false;
  DateTime? _lastConnectAttempt;

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

  void _connect() {
    if (_isDisposed || _isConnected) return;

    // Prevent connection attempts too close together
    final now = DateTime.now();
    if (_lastConnectAttempt != null &&
        now.difference(_lastConnectAttempt!).inSeconds < 2) {
      return;
    }

    _lastConnectAttempt = now;

    try {
      debugPrint("Connecting to ${url.toString()}");

      _channel = WebSocketChannel.connect(url);

      _channel!.stream.listen(
        (message) {
          _isConnected = true;
          if (!_isDisposed && !_controller.isClosed) {
            _controller.add(message);
          }
        },
        onError: (error) {
          debugPrint("WebSocket error: $error");
          _handleDisconnect();
        },
        onDone: () {
          debugPrint("WebSocket connection closed");
          _handleDisconnect();
        },
        cancelOnError: false,
      );
    } catch (e, stack) {
      debugPrint("WebSocket connection error: $e");
      debugPrint(stack.toString());
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    _isConnected = false;

    if (!_isDisposed) {
      _attemptReconnect();
    }
  }

  void _attemptReconnect() {
    if (_isDisposed || _reconnectTimer != null) return;

    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      _reconnectTimer = null;
      if (!_isDisposed && !_isConnected) {
        _connect();
      }
    });
  }

  // Add method to check and ensure connection
  bool ensureConnected() {
    if (_isDisposed) return false;
    if (_isConnected && _channel != null) return true;

    _connect();
    return false;
  }

  void send(dynamic data) {
    if (_isDisposed) return;

    if (!_isConnected) {
      debugPrint("WebSocket not connected, cannot send data");
      _connect();
      return;
    }

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
