import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domains/repositories/account_unit_settings_repository.dart';

class AccountUnitSettingsRepositoryImpl extends AccountUnitSettingsRepository {
  @override
  TaskEither<String, Unit> setAccountUnit(AccountUnit accountUnit) {
    return TaskEither.tryCatch(() async {
      final sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.setString('account_unit', accountUnit.name);
      return unit;
    }, (error, stackTrace) => 'Erro ao atualizar a unidade de conta: $error');
  }

  @override
  TaskEither<String, AccountUnit> getAccountUnit() {
    return TaskEither.tryCatch(() async {
      final sharedPreferences = await SharedPreferences.getInstance();
      final accountUnit = sharedPreferences.getString('account_unit');
      switch (accountUnit) {
        case 'bitcoin':
          return AccountUnit.bitcoin;
        case 'satoshi':
          return AccountUnit.satoshi;
        default:
          return AccountUnit.satoshi;
      }
    }, (error, stackTrace) => 'Erro ao obter a unidade de conta: $error');
  }
}
