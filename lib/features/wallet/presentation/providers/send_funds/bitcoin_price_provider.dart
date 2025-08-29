import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/prices/providers/price_service_provider.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';

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

final currencySymbolProvider = Provider<String>((ref) {
  final currency = ref.watch(currencyControllerProvider);

  switch (currency.toString().toLowerCase()) {
    case 'brl':
      return 'R\$';
    case 'usd':
      return '\$';
    default:
      return 'R\$';
  }
});
