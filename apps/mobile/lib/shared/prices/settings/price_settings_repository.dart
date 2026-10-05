import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';

abstract class PriceSettingsRepository {
  TaskEither<String, Unit> setPriceSource(PriceSource source);
  TaskEither<String, Unit> setPriceCurrency(Currency currency);
  TaskEither<String, Unit> setBalanceVisibility(bool isVisible);

  TaskEither<String, PriceServiceConfig> getPriceServiceConfig();
  TaskEither<String, bool> getBalanceVisibility();
}

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
  TaskEither<String, Unit> setBalanceVisibility(bool isVisible) {
    return TaskEither.tryCatch(
      () async {
        final sharedPreferences = await SharedPreferences.getInstance();
        await sharedPreferences.setBool('balance_visibility', isVisible);
        return unit;
      },
      (error, stackTrace) =>
          'Erro ao atualizar a visibilidade do saldo: $error',
    );
  }

  TaskEither<String, PriceSource> _getPriceSource() {
    return TaskEither.tryCatch(() async {
      final sharedPreferences = await SharedPreferences.getInstance();
      final priceSource = sharedPreferences.getString('price_source');

      switch (priceSource) {
        case "coingecko":
          return PriceSource.coingecko;
        default:
          return PriceSource.coingecko;
      }
    }, (error, stackTrace) => 'Erro ao obter a fonte de preço: $error');
  }

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

  @override
  TaskEither<String, bool> getBalanceVisibility() {
    return TaskEither.tryCatch(() async {
      final sharedPreferences = await SharedPreferences.getInstance();
      return sharedPreferences.getBool('balance_visibility') ?? true;
    }, (error, stackTrace) => 'Erro ao obter a visibilidade do saldo: $error');
  }

  @override
  TaskEither<String, PriceServiceConfig> getPriceServiceConfig() {
    return _getPriceSource().flatMap(
      (priceSource) => getPriceCurrency().map(
        (currency) =>
            PriceServiceConfig(currency: currency, priceSource: priceSource),
      ),
    );
  }
}
