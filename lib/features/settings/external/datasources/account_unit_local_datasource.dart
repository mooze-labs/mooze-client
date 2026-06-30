import 'package:shared_preferences/shared_preferences.dart';
import 'package:mooze_mobile/features/settings/domain/entities/account_unit.dart';
import 'package:mooze_mobile/features/settings/infra/datasources/account_unit_datasource.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

/// Account Unit Local Data Source Implementation (External Layer)
///
/// Storage Key: 'account_unit'
/// Default: AccountUnit.satoshi
///
/// To switch storage (e.g., to secure storage),
/// create a new implementation of AccountUnitDataSource
/// and update the provider - no other layers need to change.
class AccountUnitLocalDataSource implements AccountUnitDataSource {
  static const String _key = 'account_unit';

  @override
  Future<Result<void>> setAccountUnit(AccountUnit unit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, unit.name);
      return const Success(null);
    } catch (e) {
      return Failure(
        'Erro ao atualizar a unidade de conta: ${e.toString()}',
        e as Exception?,
      );
    }
  }

  @override
  Future<Result<AccountUnit>> getAccountUnit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_key);
      switch (value) {
        case 'bitcoin':
          return const Success(AccountUnit.bitcoin);
        case 'satoshi':
          return const Success(AccountUnit.satoshi);
        default:
          return const Success(AccountUnit.satoshi);
      }
    } catch (e) {
      return Failure(
        'Erro ao obter a unidade de conta: ${e.toString()}',
        e as Exception?,
      );
    }
  }
}
