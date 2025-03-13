import 'dart:async';
import 'dart:convert';
import 'package:mooze_mobile/utils/websocket.dart';
import 'package:lwk/lwk.dart';

class SideswapRepository {
  final WebSocketService _webSocketService;
  final bool _isTestnet;

  int _requestId = 1;
  final Map<int, Completer<dynamic>> _completers = {};
  final StreamController<Map<String, dynamic>> _notificationsController =
      StreamController<Map<String, dynamic>>.broadcast();

  bool _isInitialized = false;

  // Constructor with optional parameter for testnet
  SideswapRepository({bool isTestnet = false})
    : _isTestnet = isTestnet,
      _webSocketService = WebSocketService(
        Uri.parse(
          isTestnet
              ? "wss://api-testnet.sideswap.io/json-rpc"
              : "wss://api.sideswap.io/json-rpc",
        ),
      );

  // Initialize repository
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Subscribe to incoming messages
    _webSocketService.stream.listen((message) {
      final Map<String, dynamic> response = json.decode(message);

      // Check if it's a response to a request
      if (response.containsKey('id')) {
        final int id = response['id'];
        if (_completers.containsKey(id)) {
          _completers[id]!.complete(response);
          _completers.remove(id);
        }
      }
      // Otherwise, it's a notification
      else if (response.containsKey('method')) {
        _notificationsController.add(response);
      }
    });

    _isInitialized = true;
  }

  // Get stream of notifications
  Stream<Map<String, dynamic>> get notifications =>
      _notificationsController.stream;

  // Method to send a request and get a response
  Future<Map<String, dynamic>> _sendRequest(
    String method,
    Map<String, dynamic> params,
  ) async {
    await initialize();

    final int id = _requestId++;
    final completer = Completer<dynamic>();
    _completers[id] = completer;

    final request = {'id': id, 'method': method, 'params': params};

    _webSocketService.send(json.encode(request));

    final response = await completer.future as Map<String, dynamic>;
    return response;
  }

  // Get list of available markets
  Future<List<Map<String, dynamic>>> listMarkets() async {
    final response = await _sendRequest('market', {'list_markets': {}});

    if (response.containsKey('result') &&
        response['result'].containsKey('list_markets') &&
        response['result']['list_markets'].containsKey('markets')) {
      return List<Map<String, dynamic>>.from(
        response['result']['list_markets']['markets'],
      );
    }

    return [];
  }

  // Start receiving quotes
  Future<Map<String, dynamic>> startQuotes({
    required String baseAssetId,
    required String quoteAssetId,
    required String assetType, // "Base" or "Quote"
    required int amount,
    required String tradeDir, // "Buy" or "Sell"
    required List<Map<String, dynamic>> utxos,
    required String receiveAddress,
    required String changeAddress,
  }) async {
    final params = {
      'start_quotes': {
        'asset_pair': {'base': baseAssetId, 'quote': quoteAssetId},
        'asset_type': assetType,
        'amount': amount,
        'trade_dir': tradeDir,
        'utxos': utxos,
        'receive_address': receiveAddress,
        'change_address': changeAddress,
      },
    };

    final response = await _sendRequest('market', params);

    if (response.containsKey('result') &&
        response['result'].containsKey('start_quotes')) {
      return response['result']['start_quotes'];
    }

    throw Exception('Failed to start quotes');
  }

  // Get quote PSET
  Future<Map<String, dynamic>> getQuote(int quoteId) async {
    final params = {
      'get_quote': {'quote_id': quoteId},
    };

    final response = await _sendRequest('market', params);

    if (response.containsKey('result') &&
        response['result'].containsKey('get_quote')) {
      return response['result']['get_quote'];
    }

    throw Exception('Failed to get quote');
  }

  // Sign and submit transaction
  Future<String> takerSign(int quoteId, String signedPset) async {
    final params = {
      'taker_sign': {'quote_id': quoteId, 'pset': signedPset},
    };

    final response = await _sendRequest('market', params);

    if (response.containsKey('result') &&
        response['result'].containsKey('taker_sign') &&
        response['result']['taker_sign'].containsKey('txid')) {
      return response['result']['taker_sign']['txid'];
    }

    throw Exception('Failed to sign transaction');
  }

  // Helper method to format UTXOs for Sideswap
  List<Map<String, dynamic>> formatUtxos(List<TxOut> utxos) {
    return utxos
        .map(
          (utxo) => {
            'txid': utxo.outpoint.txid,
            'vout': utxo.outpoint.vout,
            'asset': utxo.unblinded.asset,
            'asset_bf': utxo.unblinded.assetBf,
            'value': utxo.unblinded.value,
            'value_bf': utxo.unblinded.valueBf,
            'redeem_script': null, // for P2WPKH (Native SegWit)
          },
        )
        .toList();
  }

  // Clean up resources
  void dispose() {
    _webSocketService.dispose();
    _notificationsController.close();
  }
}
