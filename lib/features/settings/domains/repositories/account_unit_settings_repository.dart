import 'package:fpdart/fpdart.dart';

enum AccountUnit { satoshi, bitcoin }

abstract class AccountUnitSettingsRepository {
  TaskEither<String, Unit> setAccountUnit(AccountUnit unit);
  TaskEither<String, AccountUnit> getAccountUnit();
}
