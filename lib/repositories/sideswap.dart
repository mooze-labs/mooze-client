import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mooze_mobile/models/sideswap.dart';
import 'package:mooze_mobile/services/sideswap.dart';

const String apiKey =
    "5c85504bf60e13e0d58614cb9ed86cb2c163cfa402fb3a9e63cf76c7a7af46a1";

/// Repository that handles communication with the SideSwap API
/// and transforms JSON data into model objects
class SideswapRepository {
  final SideswapService _service;
  bool _isInitialized = false;

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

  SideswapRepository({SideswapService? service})
    : _service = service ?? SideswapService();

  /// Initialize the repository by connecting to the service
  /// and setting up stream transformations
  void init() {
    if (_isInitialized) return;

    print("Starting Sideswap connection");

    _service.connect();
    _service.login(apiKey);

    // Transform raw JSON streams into model objects
    _setupStreamTransformations();

    _isInitialized = true;
  }

  /// Set up the transformations from JSON to model objects
  void _setupStreamTransformations() {
    // Server status
    serverStatusStream = _service.serverStatusStream
        .where((data) => data.containsKey('result'))
        .map((data) => ServerStatus.fromJson(data['result']));

    // Assets
    assetsStream = _service.assetsStream
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
    marketsStream = _service.marketStream
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
    _service.marketStream
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
    _service.pegStream.where((data) => data.containsKey('result')).listen((
      data,
    ) {
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
    _service.pegStatusStream.where((data) => data.containsKey('result')).listen(
      (data) {
        try {
          final statusData = data['result'];
          final pegStatus = PegOrderStatus.fromJson(statusData);
          _pegStatusController.add(pegStatus);
        } catch (e) {
          debugPrint('Error parsing peg status: $e');
        }
      },
    );
    pegStatusStream = _pegStatusController.stream;

    // Wallet balance (from subscribe_value)
    pegInWalletBalanceStream = _service.subscribedStream
        .where(
          (data) =>
              data.containsKey('params') &&
              data['params'].containsKey('value') &&
              data['params']['value'].containsKey('PegInWalletBalance'),
        )
        .map(
          (data) => data['params']['value']['PegInWalletBalance']['available'],
        );

    pegOutWalletBalanceStream = _service.subscribedStream
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
    marketDataStream = _service.marketStream
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
    _service.serverStatus();

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
    _service.assets(allAssets, embeddedIcons);

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
    _service.listMarkets();

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
    _service.peg(pegIn, receiveAddress);

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
    _service.pegStatus(pegIn, orderId);

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
    required int amount,
    required SwapDirection direction,
    required List<SwapUtxo> utxos,
    required String receiveAddress,
    required String changeAddress,
  }) {
    final tradeDir = direction == SwapDirection.sell ? "Sell" : "Buy";

    final assetPair = {"base": baseAsset, "quote": quoteAsset};

    final utxosJson = utxos.map((utxo) => utxo.toJson()).toList();

    _service.startQuotes(
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

    final subscription = _service.marketStream
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
    _service.receiveQuote(quoteId);

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

  /// Sign and submit a quote
  Future<String?> signQuote(int quoteId, String pset) async {
    final completer = Completer<String?>();

    final subscription = _service.marketStream
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
    _service.signQuote(quoteId, pset);

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
    _service.stopQuotes();
  }

  /// Subscribe to pegin wallet balance updates
  void subscribeToPegInWalletBalance() {
    _service.subscribeValue("PegInWalletBalance");
  }

  /// Subscribe to pegout wallet balance updates
  void subscribeToPegOutWalletBalance() {
    _service.subscribeValue("PegOutWalletBalance");
  }

  /// Subscribe to pegin wallet balance updates
  void unsubscribeToPegInWalletBalance() {
    _service.unsubscribeValue("PegInWalletBalance");
  }

  /// Subscribe to pegout wallet balance updates
  void unsubscribeToPegOutWalletBalance() {
    _service.unsubscribeValue("PegOutWalletBalance");
  }

  /// Subscribe to asset price market data
  void subscribeToAssetPriceStream(String baseAsset, String quoteAsset) {
    _service.subscribeToPriceStream(baseAsset, quoteAsset);
  }

  /// Unsubscribe from price chart data
  void unsubscribeFromAssetPriceStream(String baseAsset, String quoteAsset) {
    _service.unsubscribeFromPriceStream(baseAsset, quoteAsset);
  }

  /// Clean up resources
  void dispose() {
    _pegResponseController.close();
    _pegStatusController.close();
    _quoteResponseController.close();
  }
}
