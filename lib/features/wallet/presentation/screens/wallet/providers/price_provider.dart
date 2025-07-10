import 'package:flutter_riverpod/flutter_riverpod.dart';

final priceProvider = FutureProvider.autoDispose<double>((ref) async {
  /*
  final response = await http.get(
    Uri.parse('https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd'),
  );
  return response.body;
  */
  return 550000.0;
});
