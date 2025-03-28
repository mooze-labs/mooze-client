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

  WebSocketService(this.url) {
    // Connect when first listener is added
    _controller.onListen = () {
      if (!_isConnected && !_isDisposed) {
        _connect();
      }
    };
  }

  Stream<dynamic> get stream => _controller.stream;

  void _connect() {
    if (_isDisposed || _isConnected) return;

    try {
      print("Connecting to ${url.toString()}");

      // Use WebSocketChannel.connect with the proper URL
      _channel = WebSocketChannel.connect(url);
      _isConnected = true;

      print("WebSocket connected");

      _channel!.stream.listen(
        (message) {
          if (!_isDisposed && !_controller.isClosed) {
            _controller.add(message);
          }
        },
        onError: (error) {
          print("WebSocket error: $error");
          _handleDisconnect();
        },
        onDone: () {
          print("WebSocket connection closed");
          _handleDisconnect();
        },
        cancelOnError: false,
      );
    } catch (e, stack) {
      print("WebSocket connection error: $e");
      print(stack);
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

  void send(dynamic data) {
    if (_isDisposed) return;

    if (!_isConnected) {
      print("WebSocket not connected, cannot send data");
      _connect();
      return;
    }

    try {
      _channel?.sink.add(data);
    } catch (e) {
      print("Error sending WebSocket data: $e");
      _handleDisconnect();
    }
  }

  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;

    // Cancel reconnect timer
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    // Close the WebSocket channel
    try {
      if (_channel != null) {
        _channel!.sink.close(status.normalClosure);
      }
    } catch (e) {
      print("Error closing WebSocket channel: $e");
    }

    // Close the controller
    try {
      if (!_controller.isClosed) {
        _controller.close();
      }
    } catch (e) {
      print("Error closing controller: $e");
    }
  }
}
