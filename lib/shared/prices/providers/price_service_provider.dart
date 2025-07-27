import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../models.dart';
import '../services.dart';
import '../settings.dart';

final priceServiceProvider = Provider<TaskEither<String, PriceService>>((ref) {
  final service = PriceSettingsRepositoryImpl().getPriceServiceConfig().flatMap(
    (c) {
      switch (c.priceSource) {
        case PriceSource.coingecko:
          return TaskEither.right(CoingeckoPriceServiceImpl(c.currency));
        case PriceSource.mock:
          return TaskEither.right(MockPriceServiceImpl(c.currency));
      }
    },
  );

  return service;
});
