import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services.dart';
import '../models.dart';

final priceServiceProvider = Provider.family<PriceService, PriceServiceConfig>((
  ref,
  config,
) {
  switch (config.priceSource) {
    case PriceSource.coingecko:
      return CoingeckoPriceServiceImpl(config.currency);
    case PriceSource.mock:
      return MockPriceServiceImpl(config.currency);
  }
});
