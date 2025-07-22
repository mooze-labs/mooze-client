// Taken and modified from Satsails implementation: https://github.com/Satsails/Satsails
// GPL license: https://github.com/Satsails/Satsails?tab=GPL-2.0-1-ov-file
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mooze_mobile/utils/websocket.dart';

import '../models.dart';
import '../../domain/entities.dart';

const String sideswapApiUrl = 'wss://api.sideswap.io/json-rpc-ws';

class SideswapApi {
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

  SideswapApi() {
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
    required BigInt amount,
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
          "amount": amount.toInt(),
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

class SideswapService {
  final SideswapApi _api;
  final String _apiKey;
  bool _isInitialized = false;
  bool _isConnectionActive = false;

  // Transformed streams
  late Stream<ServerStatus> serverStatusStream;
  late Stream<List<SideswapAsset>> assetsStream;
  late Stream<List<SideswapMarket>> marketsStream;
  late Stream<QuoteResponse> quoteResponseStream;
  late Stream<PegOrderResponse> pegResponseStream;
  late Stream<PegOrderStatus> pegStatusStream;
  late Stream<int> pegInWalletBalanceStream;
  late Stream<int> pegOutWalletBalanceStream;
  late Stream<List<AssetPairMarketData>> marketDataStream;

  // Controllers for transformed data
  final _pegResponseController = StreamController<PegOrderResponse>.broadcast();
  final _pegStatusController = StreamController<PegOrderStatus>.broadcast();
  final _quoteResponseController = StreamController<QuoteResponse>.broadcast();

  SideswapService({required SideswapApi api, required String apiKey})
    : _api = api,
      _apiKey = apiKey;

  /// Initialize the repository by connecting to the service
  /// and setting up stream transformations
  void init() {
    if (_isInitialized) return;
    if (_isConnectionActive) return;

    print("Starting Sideswap connection");

    _api.connect();
    _api.login(_apiKey);

    // Transform raw JSON streams into model objects
    _setupStreamTransformations();

    _isInitialized = true;
    _isConnectionActive = true;
  }

  bool ensureConnection() {
    if (_isConnectionActive) return true;

    try {
      debugPrint("[Sideswap] Connection check - reconnecting");
      init();
      return true;
    } catch (e) {
      debugPrint("[Sideswap] Connection check failed: $e");
      return false;
    }
  }

  /// Set up the transformations from JSON to model objects
  void _setupStreamTransformations() {
    // Server status
    serverStatusStream = _api.serverStatusStream
        .where((data) => data.containsKey('result'))
        .map((data) => ServerStatus.fromJson(data['result']));

    // Assets
    assetsStream = _api.assetsStream
        .where(
          (data) =>
              data.containsKey('result') &&
              data['result'].containsKey('assets'),
        )
        .map((data) {
          final assetsJson = data['result']['assets'] as List;
          return assetsJson
              .map((asset) => SideswapAsset.fromJson(asset))
              .toList();
        });

    // Markets
    marketsStream = _api.marketStream
        .where(
          (data) =>
              data.containsKey('result') &&
              data['result'].containsKey('list_markets') &&
              data['result']['list_markets'].containsKey('markets'),
        )
        .map((data) {
          final marketsJson = data['result']['list_markets']['markets'] as List;
          return marketsJson
              .map((market) => SideswapMarket.fromJson(market))
              .toList();
        });

    // Quote responses
    _api.marketStream
        .where(
          (data) =>
              data.containsKey('params') && data['params'].containsKey('quote'),
        )
        .listen((data) {
          try {
            final quoteData = data['params']['quote'];
            final quoteResponse = QuoteResponse.fromJson(quoteData);
            _quoteResponseController.add(quoteResponse);
          } catch (e) {
            debugPrint('Error parsing quote response: $e');
          }
        });
    quoteResponseStream = _quoteResponseController.stream;

    // Peg responses
    _api.pegStream.where((data) => data.containsKey('result')).listen((data) {
      try {
        final pegData = data['result'];
        final pegResponse = PegOrderResponse.fromJson(pegData);
        _pegResponseController.add(pegResponse);
      } catch (e) {
        debugPrint('Error parsing peg response: $e');
      }
    });
    pegResponseStream = _pegResponseController.stream;

    // Peg status
    _api.pegStatusStream.where((data) => data.containsKey('result')).listen((
      data,
    ) {
      try {
        final statusData = data['result'];
        final pegStatus = PegOrderStatus.fromJson(statusData);
        _pegStatusController.add(pegStatus);
      } catch (e) {
        debugPrint('Error parsing peg status: $e');
      }
    });
    pegStatusStream = _pegStatusController.stream;

    // Wallet balance (from subscribe_value)
    pegInWalletBalanceStream = _api.subscribedStream
        .where(
          (data) =>
              data.containsKey('params') &&
              data['params'].containsKey('value') &&
              data['params']['value'].containsKey('PegInWalletBalance'),
        )
        .map(
          (data) => data['params']['value']['PegInWalletBalance']['available'],
        );

    pegOutWalletBalanceStream = _api.subscribedStream
        .where(
          (data) =>
              data.containsKey('params') &&
              data['params'].containsKey('value') &&
              data['params']['value'].containsKey('PegOutWalletBalance'),
        )
        .map((data) {
          return data['params']['value']['PegOutWalletBalance']['available'];
        });

    // Market data
    marketDataStream = _api.marketStream
        .where(
          (data) =>
              data.containsKey('result') &&
              data['result'].containsKey('chart_sub') &&
              data['result']['chart_sub'].containsKey('data'),
        )
        .map((data) {
          final marketData = data['result']['chart_sub']['data'] as List;
          return marketData
              .map((point) => AssetPairMarketData.fromJson(point))
              .toList();
        });
  }

  /// Get server status
  Future<ServerStatus?> getServerStatus() async {
    final completer = Completer<ServerStatus?>();

    final subscription = serverStatusStream.listen((status) {
      if (!completer.isCompleted) {
        completer.complete(status);
      }
    });

    // Request server status
    _api.serverStatus();

    // Add timeout to avoid hanging forever
    Future.delayed(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });

    final result = await completer.future;
    subscription.cancel();
    return result;
  }

  /// Get list of available assets
  Future<List<SideswapAsset>> getAssets({
    bool allAssets = true,
    bool embeddedIcons = false,
  }) async {
    final completer = Completer<List<SideswapAsset>>();

    final subscription = assetsStream.listen((assets) {
      if (!completer.isCompleted) {
        completer.complete(assets);
      }
    });

    // Request assets
    _api.assets(allAssets, embeddedIcons);

    // Add timeout
    Future.delayed(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        completer.complete([]);
      }
    });

    final result = await completer.future;
    subscription.cancel();
    return result;
  }

  /// Get list of available markets
  Future<List<SideswapMarket>> getMarkets() async {
    final completer = Completer<List<SideswapMarket>>();

    final subscription = marketsStream.listen((markets) {
      if (!completer.isCompleted) {
        completer.complete(markets);
      }
    });

    // Request markets
    _api.listMarkets();

    // Add timeout
    Future.delayed(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        completer.complete([]);
      }
    });

    final result = await completer.future;
    subscription.cancel();
    return result;
  }

  /// Start a peg-in/peg-out operation
  Future<PegOrderResponse?> startPegOperation(
    bool pegIn,
    String receiveAddress,
  ) async {
    final completer = Completer<PegOrderResponse?>();

    final subscription = pegResponseStream.listen((response) {
      if (!completer.isCompleted) {
        completer.complete(response);
      }
    });

    // Request peg operation
    _api.peg(pegIn, receiveAddress);

    // Add timeout
    Future.delayed(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });

    final result = await completer.future;
    subscription.cancel();
    return result;
  }

  /// Get status of a peg-in/peg-out operation
  Future<PegOrderStatus?> getPegStatus(bool pegIn, String orderId) async {
    final completer = Completer<PegOrderStatus?>();

    final subscription = pegStatusStream.listen((status) {
      if (!completer.isCompleted) {
        completer.complete(status);
      }
    });

    // Request peg status
    _api.pegStatus(pegIn, orderId);

    // Add timeout
    Future.delayed(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });

    final result = await completer.future;
    subscription.cancel();
    return result;
  }

  /// Start a quote for a swap
  void startQuote({
    required String baseAsset,
    required String quoteAsset,
    required String assetType,
    required BigInt amount,
    required SwapDirection direction,
    required List<SwapUtxo> utxos,
    required String receiveAddress,
    required String changeAddress,
  }) {
    final tradeDir = direction == SwapDirection.sell ? "Sell" : "Buy";

    final assetPair = {"base": baseAsset, "quote": quoteAsset};

    final utxosJson = utxos.map((utxo) => utxo.toJson()).toList();

    _api.startQuotes(
      assetPair: assetPair,
      assetType: assetType,
      amount: amount,
      tradeDir: tradeDir,
      utxos: utxosJson,
      receiveAddress: receiveAddress,
      changeAddress: changeAddress,
    );
  }

  /// Get quote details
  Future<String?> getQuoteDetails(int quoteId) async {
    final completer = Completer<String?>();

    final subscription = _api.marketStream
        .where(
          (data) =>
              data.containsKey('result') &&
              data['result'].containsKey('get_quote') &&
              data['result']['get_quote'].containsKey('pset'),
        )
        .listen((data) {
          if (!completer.isCompleted) {
            completer.complete(data['result']['get_quote']['pset']);
          }
        });

    // Request quote
    _api.receiveQuote(quoteId);

    // Add timeout
    Future.delayed(const Duration(seconds: 30), () {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });

    final result = await completer.future;
    subscription.cancel();
    return result;
  }

  /// Sign and submit a quote
  Future<String?> signQuote(int quoteId, String pset) async {
    final completer = Completer<String?>();

    final subscription = _api.marketStream
        .where(
          (data) =>
              data.containsKey('result') &&
              data['result'].containsKey('taker_sign') &&
              data['result']['taker_sign'].containsKey('txid'),
        )
        .listen((data) {
          if (!completer.isCompleted) {
            completer.complete(data['result']['taker_sign']['txid']);
          }
        });

    // Send signed quote
    _api.signQuote(quoteId, pset);

    // Add timeout
    Future.delayed(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });

    final result = await completer.future;
    subscription.cancel();
    return result;
  }

  void stopQuotes() {
    _api.stopQuotes();
  }

  /// Subscribe to pegin wallet balance updates
  void subscribeToPegInWalletBalance() {
    _api.subscribeValue("PegInWalletBalance");
  }

  /// Subscribe to pegout wallet balance updates
  void subscribeToPegOutWalletBalance() {
    _api.subscribeValue("PegOutWalletBalance");
  }

  /// Subscribe to pegin wallet balance updates
  void unsubscribeToPegInWalletBalance() {
    _api.unsubscribeValue("PegInWalletBalance");
  }

  /// Subscribe to pegout wallet balance updates
  void unsubscribeToPegOutWalletBalance() {
    _api.unsubscribeValue("PegOutWalletBalance");
  }

  /// Subscribe to asset price market data
  void subscribeToAssetPriceStream(String baseAsset, String quoteAsset) {
    _api.subscribeToPriceStream(baseAsset, quoteAsset);
  }

  /// Unsubscribe from price chart data
  void unsubscribeFromAssetPriceStream(String baseAsset, String quoteAsset) {
    _api.unsubscribeFromPriceStream(baseAsset, quoteAsset);
  }

  /// Clean up resources
  void dispose() {
    _pegResponseController.close();
    _pegStatusController.close();
    _quoteResponseController.close();
    _isConnectionActive = false;
  }
}
