import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../models/price_service_config.dart';
import '../services.dart';
import '../store/price_quotes_notifier.dart';

final priceServiceProvider = Provider<TaskEither<String, PriceService>>((ref) {
  ref.keepAlive();
  final currency = ref.watch(
    priceQuotesProvider.select((s) => s.currency),
  );
  final service = HybridPriceService(currency, PriceSource.coingecko);
  return TaskEither.right(service);
});
