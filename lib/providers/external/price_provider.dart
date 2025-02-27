import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// A StreamProvider that fetches BTC price in BRL every minute.
final bitcoinPriceProvider = StreamProvider.autoDispose<double>((ref) {
  final periodicStream = Stream<void>.periodic(const Duration(minutes: 1));

  return periodicStream
      .asyncMap((_) => _fetchBitcoinPrice())
      .startWithFuture(_fetchBitcoinPrice()); // immediate fetch
});

Future<double> _fetchBitcoinPrice() async {
  final url = Uri.parse(
    "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=brl",
  );
  final response = await http.get(url);
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final brlPrice = data["bitcoin"]["brl"] as num;
    return brlPrice.toDouble();
  } else {
    throw Exception(
      "Erro ao buscar preço do Bitcoin: ${response.reasonPhrase}",
    );
  }
}

/// Extension method on Stream to prepend a Future's result
extension StartWithFuture<T> on Stream<T> {
  Stream<T> startWithFuture(Future<T> future) async* {
    yield await future; // emit once immediately
    yield* this; // then continue with periodic stream
  }
}
