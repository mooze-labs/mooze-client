import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;

const coingeckoBaseUrl = 'https://api.coingecko.com/api/v3';

/// Longest wait for one price request. Without it, a stalled connection
/// holds the price refresh until the system gives up, often a minute or
/// more, before the fallback source is tried.
const priceRequestTimeout = Duration(seconds: 8);

class CoingeckoApi {
  final http.Client client = http.Client();

  CoingeckoApi();

  TaskEither<String, Option<Map<String, Map<String, double>>>> getCoinPrice(
    List<String> coins,
    String currency,
  ) {
    return TaskEither.tryCatch(() async {
      final response = await client
          .get(
            Uri.parse(
              '$coingeckoBaseUrl/simple/price?ids=${coins.join(',')}'
              '&vs_currencies=$currency&precision=full',
            ),
          )
          // A stalled request fails fast, so the fallback source answers.
          .timeout(priceRequestTimeout);
      if (response.statusCode == 200) {
        final Map<String, dynamic> rawData = jsonDecode(response.body);
        final Map<String, Map<String, double>> data = {};

        // Convert the raw response to the expected format
        rawData.forEach((coinId, currencyData) {
          if (currencyData is Map<String, dynamic>) {
            final Map<String, double> currencyMap = {};
            currencyData.forEach((currency, value) {
              if (value is num) {
                currencyMap[currency] = value.toDouble();
              }
            });
            data[coinId] = currencyMap;
          }
        });

        return Option.of(data);
      }
      return Option.none();
    }, (error, stackTrace) => 'Error fetching coin price: $error');
  }
}
