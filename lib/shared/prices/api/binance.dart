import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;

const String binanceApiHost = "data-api.binance.vision";
const String binanceApiPath = "/api/v3/";
const String binanceApiUrl = "https://data-api.binance.vision/api/v3/";
const String symbols = "[\"BTCBRL\",\"BTCUSDT\",\"USDTBRL\"]";

class BinancePriceCache {
  static final BinancePriceCache _instance = BinancePriceCache._internal();
  factory BinancePriceCache() => _instance;
  BinancePriceCache._internal();

  List<Map<String, dynamic>>? _cachedData;
  DateTime? _lastFetch;
  final Map<String, List<List<dynamic>>> _cachedKlines = {};
  final Map<String, DateTime> _klinesLastFetch = {};
  static const Duration _cacheDuration = Duration(seconds: 60);

  bool get _shouldRefresh =>
      _lastFetch == null ||
      DateTime.now().difference(_lastFetch!) > _cacheDuration;

  bool _shouldRefreshKlines(String symbol) =>
      !_klinesLastFetch.containsKey(symbol) ||
      DateTime.now().difference(_klinesLastFetch[symbol]!) > _cacheDuration;

  TaskEither<String, List<Map<String, dynamic>>> getCachedPrices(
    BinanceApi api,
  ) {
    if (_shouldRefresh) {
      return api.fetchPrices().map((data) {
        _cachedData = data;
        _lastFetch = DateTime.now();
        return data;
      });
    }
    return TaskEither.right(_cachedData!);
  }

  TaskEither<String, List<List<dynamic>>> getCachedKlines(
    BinanceApi api,
    String symbol,
    String interval,
    int startTime,
    int endTime,
  ) {
    final cacheKey = "${symbol}_${interval}_${startTime}_$endTime";

    if (_shouldRefreshKlines(cacheKey)) {
      return api.fetchKlines(symbol, interval, startTime, endTime).map((data) {
        _cachedKlines[cacheKey] = data;
        _klinesLastFetch[cacheKey] = DateTime.now();
        return data;
      });
    }
    return TaskEither.right(_cachedKlines[cacheKey]!);
  }
}

class BinanceApi {
  BinanceApi();

  TaskEither<String, List<Map<String, dynamic>>> fetchPrices() {
    final url = Uri.https(binanceApiHost, "${binanceApiPath}ticker/24hr", {
      "symbols": symbols,
    });

    return _get(url).flatMap((response) {
      if (response.statusCode != 200) {
        return TaskEither.left(
          "Failed to query Binance API: ${response.statusCode}",
        );
      }

      return TaskEither.right(
        List<Map<String, dynamic>>.from(jsonDecode(response.body)),
      );
    });
  }

  TaskEither<String, List<List<dynamic>>> fetchKlines(
    String symbol,
    String interval,
    int startTime,
    int endTime,
  ) {
    final url = Uri.https(binanceApiHost, "${binanceApiPath}klines", {
      "symbol": symbol,
      "interval": interval,
      "startTime": startTime.toString(),
      "endTime": endTime.toString(),
    });

    return _get(url).flatMap((response) {
      if (response.statusCode != 200) {
        return TaskEither.left(
          "Failed to query Binance Klines API: ${response.statusCode}",
        );
      }

      return TaskEither.right(
        List<List<dynamic>>.from(jsonDecode(response.body)),
      );
    });
  }

  TaskEither<String, http.Response> _get(Uri url) {
    return TaskEither.tryCatch(
      () async => await http.get(url),
      (err, stackTrace) => err.toString(),
    );
  }
}
