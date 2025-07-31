import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/providers.dart';

final fiatPriceProvider = FutureProvider.autoDispose.family<Either<String, double>, Asset>((ref, asset) async {
  final priceService = ref.read(priceServiceProvider);

  return await priceService.flatMap(
      (svc) => svc.getCoinPrice(asset).flatMap(
          (optDouble) => optDouble.fold(
              () => TaskEither<String, double>.left("N/A"),
              (val) => TaskEither<String, double>.right(val))
      )
  ).run();
});

final assetPriceHistoryProvider = FutureProvider.autoDispose.family<Either<String, List<double>>, Asset>((ref, asset) async {
  final priceHistorySvc = ref.read(priceHistoryServiceProvider);
  
  return await priceHistorySvc.flatMap((service) => service.get24hrKlines(asset)).run();
});

final assetPercentageVariationProvider = FutureProvider.autoDispose.family<Either<String, double>, Asset>((ref, asset) async {
  final priceHistorySvc = ref.read(priceHistoryServiceProvider);

  return await priceHistorySvc.flatMap((service) => service.getPercentageVariation(asset)).run();
});