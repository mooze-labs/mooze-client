import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/prices/settings.dart';

import '../services.dart';

final priceHistoryServiceProvider = Provider<TaskEither<String, DailyPriceVariationService>>((ref) {
  return PriceSettingsRepositoryImpl().getPriceServiceConfig().flatMap(
      (c) => TaskEither.right(BinanceDailyPriceVariationService(c.currency))
  );
});