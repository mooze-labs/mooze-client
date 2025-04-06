// Taken and modified from Satsails implementation: https://github.com/Satsails/Satsails
// GPL license: https://github.com/Satsails/Satsails?tab=GPL-2.0-1-ov-file
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mooze_mobile/utils/websocket.dart';

const String sideswapApiUrl = 'wss://api.sideswap.io/json-rpc-ws';

class SideswapService {
  late WebSocketService _wsService;
  final _loginController = StreamController<Map<String, dynamic>>.broadcast();
  final _pegController = StreamController<Map<String, dynamic>>.broadcast();
  final _pegStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _subscribeController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _unsubscribeController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _subscribedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _serverStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _assetsController = StreamController<Map<String, dynamic>>.broadcast();
  final _marketController = StreamController<Map<String, dynamic>>.broadcast();

  bool _isInitialized = false;

  Stream<Map<String, dynamic>> get loginStream => _loginController.stream;
  Stream<Map<String, dynamic>> get pegStream => _pegController.stream;
  Stream<Map<String, dynamic>> get pegStatusStream =>
      _pegStatusController.stream;
  Stream<Map<String, dynamic>> get subscribeStream =>
      _subscribeController.stream;
  Stream<Map<String, dynamic>> get unsubscribeStream =>
      _unsubscribeController.stream;
  Stream<Map<String, dynamic>> get subscribedStream =>
      _subscribedController.stream;
  Stream<Map<String, dynamic>> get serverStatusStream =>
      _serverStatusController.stream;
  Stream<Map<String, dynamic>> get assetsStream => _assetsController.stream;
  Stream<Map<String, dynamic>> get marketStream => _marketController.stream;

  SideswapService() {
    _wsService = WebSocketService(Uri.parse(sideswapApiUrl));
    _setupStreamListeners();
  }

  void _setupStreamListeners() {
    _wsService.stream.listen(
      (message) {
        try {
          final data = json.decode(message);
          _handleMessage(data);
        } catch (e) {
          debugPrint('Error decoding message: $e');
        }
      },
      onError: (error) {
        debugPrint('WebSocket stream error: $error');
      },
    );
  }

  void _handleMessage(Map<String, dynamic> data) {
    if (data.containsKey('method')) {
      final method = data['method'];
      if (kDebugMode) {
        debugPrint('Sideswap message: $data');
      }
      switch (method) {
        case "login_client":
          _loginController.add(data);
          break;
        case "peg":
          _pegController.add(data);
          break;
        case "peg_status":
          _pegStatusController.add(data);
          break;
        case "subscribe_value":
          _subscribeController.add(data);
          break;
        case "unsubscribe_value":
          _unsubscribeController.add(data);
          break;
        case "subscribed_value":
          _subscribedController.add(data);
          break;
        case "server_status":
          _serverStatusController.add(data);
          break;
        case "assets":
          _assetsController.add(data);
          break;
        case "market":
          _marketController.add(data);
          break;
      }
    }
  }

  void connect() {
    if (_isInitialized) return;
    _isInitialized = true;
    _wsService.ensureConnected();
  }

  void login(String apiKey) {
    _sendMessage({
      "id": 1,
      "method": "login_client",
      "params": {
        "api_key": apiKey,
        "user_agent": "MoozeClient",
        "version": "1.0.0",
      },
    });
  }

  void _sendMessage(Map<String, dynamic> message) {
    if (!_wsService.isConnected) {
      debugPrint('WebSocket not connected, attempting to connect...');
      _wsService.ensureConnected();
    }
    _wsService.send(json.encode(message));
    if (kDebugMode) {
      debugPrint('Sideswap message sent: $message');
    }
  }

  void serverStatus() {
    _sendMessage({"id": 1, "method": "server_status", "params": null});
  }

  void peg(bool pegIn, String recvAddr) {
    _sendMessage({
      "id": 1,
      "method": "peg",
      "params": {"peg_in": pegIn, "recv_addr": recvAddr},
    });
  }

  void pegStatus(bool pegIn, String orderId) {
    _sendMessage({
      "id": 1,
      "method": "peg_status",
      "params": {"peg_in": pegIn, "order_id": orderId},
    });
  }

  void subscribeValue(String value) {
    _sendMessage({
      "id": 1,
      "method": "subscribe_value",
      "params": {"value": value},
    });
  }

  void unsubscribeValue(String value) {
    _sendMessage({
      "id": 1,
      "method": "unsubscribe_value",
      "params": {"value": value},
    });
  }

  void assets(bool allAssets, bool embeddedIcons) {
    _sendMessage({
      "id": 1,
      "method": "assets",
      "params": {"all_assets": allAssets, "embedded_icons": embeddedIcons},
    });
  }

  void listMarkets() {
    _sendMessage({
      "id": 1,
      "method": "market",
      "params": {"list_markets": {}},
    });
  }

  void startQuotes({
    required Map<String, String> assetPair,
    required String assetType,
    required int amount,
    required String tradeDir,
    required List<Map<String, dynamic>>? utxos,
    required String receiveAddress,
    required String changeAddress,
  }) {
    _sendMessage({
      "id": 1,
      "method": "market",
      "params": {
        "start_quotes": {
          "asset_pair": {
            "base": assetPair["base"],
            "quote": assetPair["quote"],
          },
          "asset_type": assetType,
          "amount": amount,
          "trade_dir": tradeDir,
          "utxos": utxos,
          "receive_address": receiveAddress,
          "change_address": changeAddress,
        },
      },
    });
  }

  void receiveQuote(int quoteId) {
    _sendMessage({
      "id": 1,
      "method": "market",
      "params": {
        "get_quote": {"quote_id": quoteId},
      },
    });
  }

  void signQuote(int quoteId, String pset) {
    _sendMessage({
      "id": 1,
      "method": "market",
      "params": {
        "taker_sign": {"quote_id": quoteId, "pset": pset},
      },
    });
  }

  void stopQuotes() {
    _sendMessage({
      "id": 1,
      "method": "market",
      "params": {"stop_quotes": {}},
    });
  }

  void subscribeToPriceStream(String baseAsset, String quoteAsset) {
    _sendMessage({
      "id": 1,
      "method": "market",
      "params": {
        "chart_sub": {
          "asset_pair": {"base": baseAsset, "quote": quoteAsset},
        },
      },
    });
  }

  void unsubscribeFromPriceStream(String baseAsset, String quoteAsset) {
    _sendMessage({
      "id": 1,
      "method": "market",
      "params": {
        "chart_unsub": {
          "asset_pair": {"base": baseAsset, "quote": quoteAsset},
        },
      },
    });
  }

  void dispose() {
    _loginController.close();
    _pegController.close();
    _pegStatusController.close();
    _subscribeController.close();
    _unsubscribeController.close();
    _subscribedController.close();
    _serverStatusController.close();
    _assetsController.close();
    _marketController.close();
    _wsService.dispose();
  }
}
