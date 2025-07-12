import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domains/repositories/price_settings_repository.dart';

class PriceSettingsRepositoryImpl extends PriceSettingsRepository {
  @override
  TaskEither<String, Unit> setPriceSource(String source) {
    return TaskEither.tryCatch(() async {
      final sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.setString('price_source', source);
      return unit;
    }, (error, stackTrace) => 'Erro ao atualizar a fonte de preço: $error');
  }

  @override
  TaskEither<String, Unit> setPriceCurrency(String currency) {
    return TaskEither.tryCatch(() async {
      final sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.setString('price_currency', currency);
      return unit;
    }, (error, stackTrace) => 'Erro ao atualizar a moeda de preço: $error');
  }

  @override
  TaskEither<String, String> getPriceSource() {
    return TaskEither.tryCatch(() async {
      final sharedPreferences = await SharedPreferences.getInstance();
      return sharedPreferences.getString('price_source') ?? 'coingecko';
    }, (error, stackTrace) => 'Erro ao obter a fonte de preço: $error');
  }

  @override
  TaskEither<String, String> getPriceCurrency() {
    return TaskEither.tryCatch(() async {
      final sharedPreferences = await SharedPreferences.getInstance();
      return sharedPreferences.getString('price_currency') ?? 'BRL';
    }, (error, stackTrace) => 'Erro ao obter a moeda de preço: $error');
  }
}
