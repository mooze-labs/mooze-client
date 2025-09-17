import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../services.dart';
import '../settings.dart';

final priceServiceProvider = Provider<TaskEither<String, PriceService>>((ref) {
  final service = PriceSettingsRepositoryImpl().getPriceServiceConfig().flatMap(
    (c) {
      return TaskEither.right(HybridPriceService(c.currency, c.priceSource));
    },
  );

  return service;
});
