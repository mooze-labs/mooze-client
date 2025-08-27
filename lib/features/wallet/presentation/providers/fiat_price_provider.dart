import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/providers.dart';
import 'package:mooze_mobile/shared/prices/services/price_service.dart';

class AssetPriceHistoryParams {
  final Asset asset;
  final KlineInterval interval;
  final int periodInDays;

  AssetPriceHistoryParams({
    required this.asset,
    required this.interval,
    required this.periodInDays,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetPriceHistoryParams &&
          runtimeType == other.runtimeType &&
          asset == other.asset &&
          interval == other.interval &&
          periodInDays == other.periodInDays;

  @override
  int get hashCode =>
      asset.hashCode ^ interval.hashCode ^ periodInDays.hashCode;
}

final currencyProvider = FutureProvider<Either<String, String>>((ref) async {
  final priceService = ref.read(priceServiceProvider);

  return await priceService
      .flatMap((svc) => TaskEither.right(svc.currency.toUpperCase()))
      .run();
});

final fiatPriceProvider = FutureProvider.autoDispose
    .family<Either<String, double>, Asset>((ref, asset) async {
      final priceService = ref.read(priceServiceProvider);

      return await priceService
          .flatMap(
            (svc) => svc
                .getCoinPrice(asset)
                .flatMap(
                  (optDouble) => optDouble.fold(
                    () => TaskEither<String, double>.left("N/A"),
                    (val) => TaskEither<String, double>.right(val),
                  ),
                ),
          )
          .run();
    });

final assetPriceHistoryProvider = FutureProvider.autoDispose
    .family<Either<String, List<double>>, Asset>((ref, asset) async {
      final priceHistorySvc = ref.read(priceHistoryServiceProvider);

      return await priceHistorySvc
          .flatMap((service) => service.get24hrKlines(asset))
          .run();
    });

final assetPriceHistoryWithPeriodProvider = FutureProvider.autoDispose
    .family<Either<String, List<double>>, AssetPriceHistoryParams>((
      ref,
      params,
    ) async {
      final priceHistorySvc = ref.read(priceHistoryServiceProvider);

      return await priceHistorySvc
          .flatMap(
            (service) => service.getKlinesForPeriod(
              params.asset,
              params.interval,
              params.periodInDays,
            ),
          )
          .run();
    });

final assetPercentageVariationProvider = FutureProvider.autoDispose
    .family<Either<String, double>, Asset>((ref, asset) async {
      final priceHistorySvc = ref.read(priceHistoryServiceProvider);

      return await priceHistorySvc
          .flatMap((service) => service.getPercentageVariation(asset))
          .run();
    });
