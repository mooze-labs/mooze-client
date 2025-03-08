import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'coingecko_price_provider.g.dart';

class CoingeckoAssetPairs {
  final List<String> assets;
  final String baseCurrency;

  CoingeckoAssetPairs({required this.assets, required this.baseCurrency});
}

@riverpod
Future<Map<String, double>> coingeckoPrice(
  Ref ref,
  CoingeckoAssetPairs coingeckoAssetPairs,
) async {
  final prices = await _fetchCoingeckoPrices(coingeckoAssetPairs);
  return prices;
}

Future<Map<String, double>> _fetchCoingeckoPrices(
  CoingeckoAssetPairs assetPairs,
) async {
  final uri = Uri.https("api.coingecko.com", "/api/v3/simple/price", {
    "ids": assetPairs.assets.join(","),
    "vs_currencies": assetPairs.baseCurrency.toLowerCase(),
  });

  final response = await http.get(uri);
  if (response.statusCode != 200) {
    throw Exception(
      "[ERROR] Failed to fetch prices: ${response.statusCode} - ${response.reasonPhrase}",
    );
  }

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  return json.map(
    (id, data) => MapEntry(
      id,
      (data[assetPairs.baseCurrency.toLowerCase()] as num).toDouble(),
    ),
  );
}
