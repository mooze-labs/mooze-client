// Taken and modified from Satsails implementation: https://github.com/Satsails/Satsails
// GPL license: https://github.com/Satsails/Satsails?tab=GPL-2.0-1-ov-file
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

const String sideswapApiUrl = 'wss://api.sideswap.io/json-rpc-ws';

class SideswapService {
  late WebSocketChannel _channel;
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

  void connect() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(sideswapApiUrl));
      _channel.stream.listen(
        _handleIncomingMessage,
        onError:
            (error) => throw Exception("Error connecting to WebSocket: $error"),
        cancelOnError: true,
      );
    } catch (e) {
      throw Exception("Error connecting to WebSocket: $e");
    }
  }

  void _handleIncomingMessage(dynamic message) {
    var decodedMessage = json.decode(message);
    print(decodedMessage);
    switch (decodedMessage["method"]) {
      case "login_client":
        _loginController.add(decodedMessage);
        break;
      case "peg":
        _pegController.add(decodedMessage);
        break;
      case "peg_status":
        _pegStatusController.add(decodedMessage);
        break;
      case "subscribe_value":
        _subscribeController.add(decodedMessage);
        break;
      case "unsubscribe_value":
        _unsubscribeController.add(decodedMessage);
        break;
      case "subscribed_value":
        _subscribedController.add(decodedMessage);
        break;
      case "server_status":
        _serverStatusController.add(decodedMessage);
        break;
      case "assets":
        _assetsController.add(decodedMessage);
        break;
      case "market":
        _marketController.add(decodedMessage);
        break;
    }
  }

  void login(String apiKey) {
    _channel.sink.add(
      json.encode({
        "id": 1,
        "method": "login_client",
        "params": {
          "api_key": apiKey,
          "user_agent": "MoozeClient",
          "version": "1.0.0",
        },
      }),
    );
  }

  void status() {
    _channel.sink.add(
      json.encode({"id": 1, "method": "server_status", "params": {}}),
    );
  }

  void peg(bool pegIn, String recvAddr) {
    _channel.sink.add(
      json.encode({
        "id": 1,
        "method": "peg",
        "params": {"peg_in": pegIn, "recv_addr": recvAddr},
      }),
    );
  }

  void pegStatus(bool pegIn, String orderId) {
    _channel.sink.add(
      json.encode({
        "id": 1,
        "method": "peg_status",
        "params": {"peg_in": pegIn, "order_id": orderId},
      }),
    );
  }

  void subscribeValue(String value) {
    _channel.sink.add(
      json.encode({
        "id": 1,
        "method": "subscribe_value",
        "params": {"value": value},
      }),
    );
  }

  void unsubscribeValue(String value) {
    _channel.sink.add(
      json.encode({
        "id": 1,
        "method": "unsubscribe_value",
        "params": {"value": value},
      }),
    );
  }

  void serverStatus() {
    _channel.sink.add(
      json.encode({"id": 1, "method": "server_status", "params": null}),
    );
  }

  void assets(bool allAssets, bool embeddedIcons) {
    _channel.sink.add(
      json.encode({
        "id": 1,
        "method": "assets",
        "params": {"all_assets": allAssets, "embedded_icons": embeddedIcons},
      }),
    );
  }

  void listMarkets() {
    _channel.sink.add(
      json.encode({
        "id": 1,
        "method": "market",
        "params": {"list_markets": {}},
      }),
    );
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
    String payload = json.encode({
      "id": 1,
      "method": "market",
      "params": {
        "start_quotes": {
          // hardcoding to Depix for now, change this later
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

    _channel.sink.add(payload);
  }

  void receiveQuote(int quoteId) {
    _channel.sink.add(
      json.encode({
        "id": 1,
        "method": "market",
        "params": {
          "get_quote": {"quote_id": quoteId},
        },
      }),
    );
  }

  void signQuote(int quoteId, String pset) {
    _channel.sink.add(
      json.encode({
        "id": 1,
        "method": "market",
        "params": {
          "taker_sign": {"quote_id": quoteId, "pset": pset},
        },
      }),
    );
  }

  void stopQuotes() {
    _channel.sink.add(
      json.encode({
        "id": 1,
        "method": "market",
        "params": {"stop_quotes": {}},
      }),
    );
  }

  void subscribeToPriceStream(String baseAsset, String quoteAsset) {
    _channel.sink.add(
      json.encode({
        "id": 1,
        "method": "market",
        "params": {
          "chart_sub": {
            "asset_pair": {
              {"base": baseAsset, "quote": quoteAsset},
            },
          },
        },
      }),
    );
  }

  void unsubscribeFromPriceStream(String baseAsset, String quoteAsset) {
    _channel.sink.add(
      json.encode({
        "id": 1,
        "method": "market",
        "params": {
          "chart_unsub": {
            "asset_pair": {
              {"base": baseAsset, "quote": quoteAsset},
            },
          },
        },
      }),
    );
  }
}
