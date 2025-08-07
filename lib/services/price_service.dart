import 'dart:convert';

import 'package:http/http.dart' as http;

const String COINGECKO_API_URL = "https://api.coingecko.com/api/v3";
const String BINANCE_API_URL = "https://data-api.binance.vision/api/v3";

enum Currency { usd, brl }

abstract class PriceService {
  Future<Map<String, double>> getPrices(Currency currency);
}

class CoingeckoService implements PriceService {
  static const String _apiUrl = COINGECKO_API_URL;
  static const List<String> _assets = ["bitcoin", "tether"];

  @override
  Future<Map<String, double>> getPrices(Currency currency) async {
    final uri = Uri.https(_apiUrl, "/simple/price", {
      "ids": _assets.join(","),
      "vs_currencies": currency.name.toLowerCase(),
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception("Failed to fetch prices");
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    return json.map(
      (id, data) =>
          MapEntry(id, (data[currency.name.toLowerCase()] as num).toDouble()),
    );
  }
}

class BinanceService {
  static const String _apiUrl = BINANCE_API_URL;
  static const List<String> _tickers = ["BTCUSDT", "BTCBRL", "USDTBRL"];

  @override
  Future<Map<String, double>> getPrices(Currency currency) async {
    final uri = Uri.https(_apiUrl, "/ticker/price", {
      "symbols": _tickers.join(","),
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception("Failed to fetch prices");
    }

    final json = jsonDecode(response.body) as List<Map<String, String>>;
    return Map.fromEntries(
      json.map((e) => MapEntry(e["symbol"]!, double.parse(e["price"]!))),
    );
  }
}
