import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:lwk/lwk.dart'; // For the Wallet class

/// Your mainnet asset IDs:
/// - LBTC: 6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d
/// - Depix: 02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189
/// - USDt: ce091c998b83c78bb71a632313ba3760f1763d9cfcffae02258ffa9865a37bd2

class SwapScreen extends StatefulWidget {
  final Wallet wallet;

  const SwapScreen({required this.wallet, Key? key}) : super(key: key);

  @override
  _SwapScreenState createState() => _SwapScreenState();
}

class _SwapScreenState extends State<SwapScreen> {
  late WebSocketChannel _channel;

  bool _isLoading = true;
  String? _errorMessage;

  // We'll store the markets returned by "list_markets" (likely testnet in the current Sideswap config)
  // But we will NOT map them to your mainnet IDs. We just show them for reference.
  List<Map<String, dynamic>> _markets = [];

  // The user picks from which asset to deliver and which asset to receive
  String _fromAsset = "Depix"; // default selection
  String _toAsset = "LBTC"; // default selection

  // The user enters an amount in a TextField
  final TextEditingController _amountController = TextEditingController();

  // We'll display any quote result that comes from "start_quotes"
  String? _quoteResult;

  // Addresses used in the "start_quotes" request
  String? _receiveAddress;
  String? _changeAddress;

  @override
  void initState() {
    super.initState();
    _initWebSocket();
    _generateAddresses();
  }

  /// Generate a receiving (and change) address from your wallet
  Future<void> _generateAddresses() async {
    try {
      final addressObj = await widget.wallet.addressLastUnused();
      setState(() {
        _receiveAddress = addressObj.confidential;
        _changeAddress = addressObj.confidential;
      });
    } catch (e) {
      print("Erro ao gerar endereço: $e");
    }
  }

  /// Open the WebSocket and send "login_client"
  void _initWebSocket() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _markets = [];
    });

    _channel = IOWebSocketChannel.connect(
      Uri.parse('wss://api.sideswap.io/json-rpc-ws'),
    );

    _channel.stream.listen(
      (message) => _handleMessage(message),
      onError: (error, stackTrace) {
        setState(() {
          _errorMessage = "WebSocket error: $error";
          _isLoading = false;
        });
      },
      onDone: () {
        if (mounted) {
          setState(() {
            _errorMessage = "WebSocket connection closed.";
            _isLoading = false;
          });
        }
      },
    );

    _loginClient();
  }

  void _loginClient() {
    final loginRequest = {
      "id": 1,
      "method": "login_client",
      "params": {
        "api_key":
            "5c85504bf60e13e0d58614cb9ed86cb2c163cfa402fb3a9e63cf76c7a7af46a1",
        "cookie": null,
        "user_agent": "<USER_AGENT>",
        "version": "<APP_VERSION>",
      },
    };
    _channel.sink.add(jsonEncode(loginRequest));
  }

  /// After login, request "list_markets" if you want to see what's available
  void _requestListMarkets() {
    final marketRequest = {
      "id": 1,
      "method": "market",
      "params": {"list_markets": {}},
    };
    _channel.sink.add(jsonEncode(marketRequest));
  }

  /// Handle all incoming messages from the WebSocket
  void _handleMessage(dynamic message) {
    final msgString = message as String;
    print("WS Message: $msgString");

    try {
      final data = jsonDecode(msgString);

      // If login succeeded, request list_markets
      if (data["method"] == "login_client" && data["result"] != null) {
        _requestListMarkets();
        return;
      }

      // If we got a "list_markets" response
      if (data["method"] == "market" &&
          data["result"] != null &&
          data["result"]["list_markets"] != null) {
        final list = data["result"]["list_markets"]["markets"];
        setState(() {
          _markets = List<Map<String, dynamic>>.from(list);
          _isLoading = false;
        });
        return;
      }

      // If we got a "start_quotes" response
      if (data["method"] == "market" &&
          data["result"] != null &&
          data["result"]["start_quotes"] != null) {
        final quotesResponse = data["result"]["start_quotes"];
        setState(() {
          _quoteResult = jsonEncode(quotesResponse);
        });
        return;
      }

      // If there's an error
      if (data["error"] != null) {
        setState(() {
          _errorMessage = data["error"]["message"];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Erro ao decodificar resposta do servidor: $e";
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  /// Build the main UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text("Swap"), backgroundColor: Colors.black),
      body: Stack(
        children: [
          Container(color: Colors.black),
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: _buildSwapBody(),
              ),
        ],
      ),
    );
  }

  Widget _buildSwapBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_errorMessage != null) ...[
          Text(
            _errorMessage!,
            style: TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
        ],
        Text(
          "Mercados (possivelmente testnet):",
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        Container(
          margin: EdgeInsets.only(bottom: 16, top: 8),
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFF1E1E1E),
            border: Border.all(color: Color(0xFFD973C1), width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          height: 100,
          child: SingleChildScrollView(
            child: Text(
              _markets.toString(),
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ),
        Text(
          "Escolha o swap:",
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        SizedBox(height: 8),
        _buildAssetDropdown(
          label: "Enviar",
          value: _fromAsset,
          items: const ["LBTC", "Depix", "USDt"],
          onChanged: (val) {
            setState(() {
              _fromAsset = val;
              // For simplicity, if fromAsset is LBTC, default toAsset is Depix
              // or if fromAsset is Depix, toAsset is LBTC, etc.
              if (_fromAsset == _toAsset) {
                if (_fromAsset == "LBTC") {
                  _toAsset = "Depix";
                } else {
                  _toAsset = "LBTC";
                }
              }
            });
          },
        ),
        SizedBox(height: 8),
        _buildAssetDropdown(
          label: "Receber",
          value: _toAsset,
          items: const ["LBTC", "Depix", "USDt"],
          onChanged: (val) {
            setState(() {
              _toAsset = val;
              if (_fromAsset == _toAsset) {
                // Switch fromAsset if user tries to pick the same
                if (_toAsset == "LBTC") {
                  _fromAsset = "Depix";
                } else {
                  _fromAsset = "LBTC";
                }
              }
            });
          },
        ),
        SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Color(0xFF1E1E1E),
            border: Border.all(color: Color(0xFFD973C1), width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Quantidade",
              labelStyle: TextStyle(color: Colors.white70),
              border: InputBorder.none,
            ),
          ),
        ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: _getQuote,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFD973C1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 30),
          ),
          child: Text(
            "Obter Cotação",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        SizedBox(height: 16),
        if (_quoteResult != null)
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF1E1E1E),
              border: Border.all(color: Color(0xFFD973C1), width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "Retorno da cotação:\n $_quoteResult",
              style: TextStyle(color: Colors.white),
            ),
          ),
      ],
    );
  }

  /// Build a labeled dropdown for the user to pick an asset
  Widget _buildAssetDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFD973C1), width: 1),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 16)),
          SizedBox(width: 16),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: Color(0xFF1E1E1E),
              icon: Icon(Icons.arrow_drop_down, color: Color(0xFFD973C1)),
              style: TextStyle(color: Colors.white),
              items:
                  items.map((String asset) {
                    return DropdownMenuItem<String>(
                      value: asset,
                      child: Text(asset),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build and send the "start_quotes" request using your mainnet asset IDs
  Future<void> _getQuote() async {
    setState(() {
      _quoteResult = null;
      _errorMessage = null;
    });

    final rawAmount = _amountController.text.trim();
    if (rawAmount.isEmpty) {
      setState(() {
        _errorMessage = "Informe um valor.";
      });
      return;
    }

    final amount = int.tryParse(rawAmount);
    if (amount == null || amount <= 0) {
      setState(() {
        _errorMessage = "Valor inválido.";
      });
      return;
    }

    if (_receiveAddress == null || _changeAddress == null) {
      setState(() {
        _errorMessage = "Ainda gerando endereços. Tente novamente.";
      });
      return;
    }

    // Your mainnet asset IDs
    const lbtcID =
        "6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d";
    const depixID =
        "02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189";
    const usdtID =
        "ce091c998b83c78bb71a632313ba3760f1763d9cfcffae02258ffa9865a37bd2";

    late String baseID;
    late String quoteID;
    late String assetType; // "Base" or "Quote"
    late String tradeDir; // "Buy" or "Sell"

    // Decide the combination
    if (_fromAsset == "Depix" && _toAsset == "LBTC") {
      baseID = depixID;
      quoteID = lbtcID;
      assetType = "Base";
      tradeDir = "Sell";
    } else if (_fromAsset == "LBTC" && _toAsset == "Depix") {
      baseID = lbtcID;
      quoteID = depixID;
      assetType = "Base";
      tradeDir = "Sell";
    } else if (_fromAsset == "USDt" && _toAsset == "LBTC") {
      baseID = usdtID;
      quoteID = lbtcID;
      assetType = "Base";
      tradeDir = "Sell";
    } else if (_fromAsset == "LBTC" && _toAsset == "USDt") {
      baseID = lbtcID;
      quoteID = usdtID;
      assetType = "Base";
      tradeDir = "Sell";
    } else {
      setState(() {
        _errorMessage = "Par de ativos inválido: $_fromAsset -> $_toAsset";
      });
      return;
    }

    final startQuotesRequest = {
      "id": 1,
      "method": "market",
      "params": {
        "start_quotes": {
          "asset_pair": {"base": baseID, "quote": quoteID},
          "asset_type": assetType,
          "amount": amount,
          "trade_dir": tradeDir,
          "utxos": [], // we won’t provide utxos for now
          "receive_address": _receiveAddress,
          "change_address": _changeAddress,
        },
      },
    };

    _channel.sink.add(jsonEncode(startQuotesRequest));
  }
}
