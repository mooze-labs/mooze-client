import 'package:fpdart/fpdart.dart';

import '../../domains/repositories/account_unit_settings_repository.dart';

class AccountUnitSettingsController {
  final AccountUnitSettingsRepository _accountUnitSettingsRepository;

  AccountUnitSettingsController({
    required AccountUnitSettingsRepository accountUnitSettingsRepository,
  }) : _accountUnitSettingsRepository = accountUnitSettingsRepository;

  TaskEither<String, Unit> setAccountUnit(AccountUnit accountUnit) {
    return _accountUnitSettingsRepository.setAccountUnit(accountUnit);
  }

  TaskEither<String, AccountUnit> getAccountUnit() {
    return _accountUnitSettingsRepository.getAccountUnit();
  }
}
