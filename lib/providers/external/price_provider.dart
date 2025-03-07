import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

// A provider to hold the list of coin IDs to query
final cryptoPriceConfigProvider = Provider<List<String>>(
  (ref) => throw UnimplementedError(),
);

// A StreamProvider.family that fetches prices for configured coins
final cryptoPriceProvider = StreamProvider.family.autoDispose<double, String>((
  ref,
  coinId,
) {
  final coinIds = ref.watch(
    cryptoPriceConfigProvider,
  ); // Get the configured coins
  final periodicStream = Stream<void>.periodic(const Duration(minutes: 5));

  print("[INFO] Creating price stream provider for asset $coinId");

  return periodicStream
      .asyncMap((_) => _fetchCryptoPrices(coinIds))
      .startWithFuture(_fetchCryptoPrices(coinIds))
      .map((prices) => prices[coinId] ?? 0.0); // Extract specific coin price
});

// Fetches prices for a list of coins in BRL
Future<Map<String, double>> _fetchCryptoPrices(List<String> coinIds) async {
  final url = Uri.parse(
    "https://api.coingecko.com/api/v3/simple/price?ids=${coinIds.join(',')}&vs_currencies=brl",
  );
  final response = await http.get(url);

  if (response.statusCode == 200) {
    print("[DEBUG] Retrieved price data.");
    final data = jsonDecode(response.body);
    print(data.toString());
    return Map.fromEntries(
      coinIds.map(
        (id) => MapEntry(id, (data[id]['brl'] as num?)?.toDouble() ?? 0.0),
      ),
    );
  } else {
    throw Exception(
      "Erro ao buscar preços das criptomoedas: ${response.reasonPhrase}",
    );
  }
}

/// Extension method on Stream to prepend a Future's result
extension StartWithFuture<T> on Stream<T> {
  Stream<T> startWithFuture(Future<T> future) async* {
    yield await future; // Emit once immediately
    yield* this; // Then continue with periodic stream
  }
}
