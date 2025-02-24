import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

/// Service to handle websocket connections.
class WebSocketService {
  final Uri url;
  late WebSocketChannel _channel;
  late final StreamController<dynamic> _controller;
  Timer? _reconnectTimer;

  WebSocketService(this.url) {
    _controller = StreamController<dynamic>.broadcast(
      onListen: _connect,
      onCancel: () {
        _closeConnection();
      },
    );
  }

  Stream<dynamic> get stream => _controller.stream;

  Future<void> _connect() async {
    _channel = WebSocketChannel.connect(url);
    await _channel.ready;

    _channel.stream.listen(
      (message) {
        _controller.add(message);
      },
      onError: (error) {
        _attemptReconnect();
      },
      onDone: () {
        _closeConnection();
      },
    );
  }

  Future<void> _attemptReconnect() async {
    if (_reconnectTimer == null || !_reconnectTimer!.isActive) {
      _reconnectTimer = Timer(Duration(seconds: 5), () async {
        await _connect();
      });
    }
  }

  void send(dynamic data) {
    _channel.sink.add(data);
  }

  void _closeConnection() {
    _reconnectTimer?.cancel();
    _channel.sink.close(status.goingAway);
    _controller.close();
  }

  void dispose() {
    _closeConnection();
  }
}
