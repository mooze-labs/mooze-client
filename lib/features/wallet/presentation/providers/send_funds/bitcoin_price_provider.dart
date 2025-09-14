import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/providers/price_service_provider.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'selected_asset_provider.dart';

final bitcoinPriceProvider = FutureProvider<double>((ref) async {
  final priceServiceResult = await ref.read(priceServiceProvider).run();

  return await priceServiceResult.fold(
    (error) async {
      throw Exception('Serviço de preços indisponível: $error');
    },
    (service) async {
      final btcPriceResult = await service.getCoinPrice(Asset.btc).run();
      return btcPriceResult.fold(
        (error) {
          throw Exception('Erro ao obter cotação do Bitcoin: $error');
        },
        (priceOption) => priceOption.fold(() {
          throw Exception('Preço do Bitcoin não disponível');
        }, (price) => price),
      );
    },
  );
});

final selectedAssetPriceProvider = FutureProvider<double>((ref) async {
  final selectedAsset = ref.watch(selectedAssetProvider);
  final priceServiceResult = await ref.read(priceServiceProvider).run();

  return await priceServiceResult.fold(
    (error) async {
      throw Exception('Serviço de preços indisponível: $error');
    },
    (service) async {
      final assetPriceResult = await service.getCoinPrice(selectedAsset).run();
      return assetPriceResult.fold(
        (error) {
          throw Exception(
            'Erro ao obter cotação de ${selectedAsset.name}: $error',
          );
        },
        (priceOption) => priceOption.fold(() {
          throw Exception('Preço de ${selectedAsset.name} não disponível');
        }, (price) => price),
      );
    },
  );
});

final currencySymbolProvider = Provider<String>((ref) {
  final currency = ref.read(currencyControllerProvider.notifier);
  return currency.icon;
});
