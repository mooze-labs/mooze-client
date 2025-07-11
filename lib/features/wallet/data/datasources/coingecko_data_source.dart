import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;

const coingeckoBaseUrl = 'https://api.coingecko.com/api/v3';

class CoingeckoDataSource {
  final http.Client client;

  CoingeckoDataSource({required this.client});

  TaskEither<String, Option<Map<String, Map<String, num>>>> getCoinPrice(
    List<String> coins,
    List<String> currencies,
  ) {
    return TaskEither.tryCatch(() async {
      final response = await client.get(
        Uri.parse(
          '$coingeckoBaseUrl/simple/price?ids=${coins.join(',')}&vs_currencies=${currencies.join(',')}',
        ),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> rawData = jsonDecode(response.body);
        final Map<String, Map<String, num>> data = {};

        // Convert the raw response to the expected format
        rawData.forEach((coinId, currencyData) {
          if (currencyData is Map<String, dynamic>) {
            final Map<String, num> currencyMap = {};
            currencyData.forEach((currency, value) {
              if (value is num) {
                currencyMap[currency] = value;
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
