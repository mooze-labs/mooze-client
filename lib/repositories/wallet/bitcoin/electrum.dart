// Based on the functionality of mrtnetwork/bitcoin_base
// https://github.com/mrtnetwork/bitcoin_base
// BSD 3-Clause License

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/service/models/params.dart';
import 'package:blockchain_utils/utils/string/string.dart';

class AsyncRequestCompleter {
  AsyncRequestCompleter(this.params);
  final Completer<Map<String, dynamic>> completer = Completer();
  final Map<String, dynamic> params;
}

class ElectrumSSLService with ElectrumServiceProvider {
  ElectrumSSLService._(
    this.url,
    SecureSocket channel, {
    this.defaultRequestTimeOut = const Duration(seconds: 30),
  }) : _socket = channel {
    _subscription = _socket!.listen(
      _onMessge,
      onError: _onClose,
      onDone: _onDone,
    );
  }
  SecureSocket? _socket;
  StreamSubscription<List<int>>? _subscription;
  final Duration defaultRequestTimeOut;

  Map<int, AsyncRequestCompleter> requests = {};
  bool _isDiscounnect = false;

  bool get isConnected => _isDiscounnect;

  final String url;

  void add(List<int> params) {
    if (_isDiscounnect) {
      throw StateError("socket has been discounected");
    }
    _socket?.add(params);
  }

  void _onClose(Object? error) {
    _isDiscounnect = true;

    _socket = null;
    _subscription?.cancel().catchError((e) {});
    _subscription = null;
  }

  void _onDone() {
    _onClose(null);
  }

  void discounnect() {
    _onClose(null);
  }

  static Future<ElectrumSSLService> connect(
    String url, {
    Iterable<String>? protocols,
    Duration defaultRequestTimeOut = const Duration(seconds: 30),
    final Duration connectionTimeOut = const Duration(seconds: 30),
  }) async {
    final parts = url.split(":");
    final channel = await SecureSocket.connect(
      parts[0],
      int.parse(parts[1]),
      onBadCertificate: (certificate) => true,
    ).timeout(connectionTimeOut);

    return ElectrumSSLService._(
      url,
      channel,
      defaultRequestTimeOut: defaultRequestTimeOut,
    );
  }

  String? ddd;
  void _onMessge(List<int> event) {
    final msg = utf8.decode(event);
    if (msg.contains("jsonrpc")) {
      ddd = msg;
    } else {
      ddd = "$ddd$msg";
    }
    Map<String, dynamic>? decode = StringUtils.tryToJson(ddd);
    if (decode?.containsKey("id") ?? false) {
      final int id = int.parse(decode!["id"]!.toString());
      final request = requests.remove(id);
      request?.completer.complete(decode);
    }
  }

  @override
  Future<BaseServiceResponse<T>> doRequest<T>(
    ElectrumRequestDetails params, {
    Duration? timeout,
  }) async {
    final AsyncRequestCompleter compeleter = AsyncRequestCompleter(
      params.params,
    );
    try {
      requests[params.requestID] = compeleter;
      add(params.toTCPParams());
      final result = await compeleter.completer.future.timeout(
        timeout ?? defaultRequestTimeOut,
      );
      return params.toResponse(result);
    } finally {
      requests.remove(params.requestID);
    }
  }
}
