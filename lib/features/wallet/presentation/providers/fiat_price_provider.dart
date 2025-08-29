import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/providers.dart';
import 'package:mooze_mobile/shared/prices/services/price_service.dart';
import 'package:mooze_mobile/shared/prices/models/price_service_config.dart';

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

final fiatPriceProvider = FutureProvider.autoDispose.family<
  Either<String, double>,
  Asset
>((ref, asset) async {
  try {
    final priceServiceResult = await ref.read(priceServiceProvider).run();

    return await priceServiceResult.fold((error) => Left(error), (svc) async {
      final priceResult = await svc.getCoinPrice(asset).run();

      return await priceResult.fold(
        (error) async {
          print(
            'DEBUG: Erro ao obter preço de ${asset.name} com moeda padrão: $error',
          );

          final currentCurrency = svc.currency.toLowerCase();
          final alternateCurrency =
              currentCurrency == 'brl' ? Currency.usd : Currency.brl;

          print(
            'DEBUG: Tentando obter preço de ${asset.name} com moeda alternativa: ${alternateCurrency.name}',
          );

          final alternateResult =
              await svc
                  .getCoinPrice(asset, optionalCurrency: alternateCurrency)
                  .run();

          return alternateResult.flatMap(
            (optDouble) => optDouble.fold(
              () => const Left("Preço não disponível em nenhuma moeda"),
              (val) {
                print('DEBUG: Preço obtido com moeda alternativa: $val');
                return Right(val);
              },
            ),
          );
        },
        (optDouble) => optDouble.fold(
          () => const Left("Preço não disponível"),
          (val) => Right(val),
        ),
      );
    });
  } catch (e) {
    print('DEBUG: Erro no fiatPriceProvider para ${asset.name}: $e');
    return Left('Erro ao obter preço: $e');
  }
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
