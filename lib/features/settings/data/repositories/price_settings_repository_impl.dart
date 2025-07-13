import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domains/repositories/price_settings_repository.dart';

class PriceSettingsRepositoryImpl extends PriceSettingsRepository {
  @override
  TaskEither<String, Unit> setPriceSource(PriceSource source) {
    return TaskEither.tryCatch(() async {
      final sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.setString('price_source', source.name);
      return unit;
    }, (error, stackTrace) => 'Erro ao atualizar a fonte de preço: $error');
  }

  @override
  TaskEither<String, Unit> setPriceCurrency(Currency currency) {
    return TaskEither.tryCatch(() async {
      final sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.setString('price_currency', currency.name);
      return unit;
    }, (error, stackTrace) => 'Erro ao atualizar a moeda de preço: $error');
  }

  @override
  TaskEither<String, PriceSource> getPriceSource() {
    return TaskEither.tryCatch(() async {
      final sharedPreferences = await SharedPreferences.getInstance();
      final priceSource = sharedPreferences.getString('price_source');

      switch (priceSource) {
        case "coingecko":
          return PriceSource.coingecko;
        case "mock":
          return PriceSource.mock;
        default:
          return PriceSource.coingecko;
      }
    }, (error, stackTrace) => 'Erro ao obter a fonte de preço: $error');
  }

  @override
  TaskEither<String, Currency> getPriceCurrency() {
    return TaskEither.tryCatch(() async {
      final sharedPreferences = await SharedPreferences.getInstance();
      final priceCurrency = sharedPreferences.getString('price_currency');

      switch (priceCurrency) {
        case "brl":
          return Currency.brl;
        case "usd":
          return Currency.usd;
        default:
          return Currency.brl;
      }
    }, (error, stackTrace) => 'Erro ao obter a moeda de preço: $error');
  }
}
