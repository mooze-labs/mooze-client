import 'package:mooze_mobile/features/settings/domain/entities/account_unit.dart';
import 'package:mooze_mobile/features/settings/domain/repositories/account_unit_repository.dart';
import 'package:mooze_mobile/features/settings/infra/datasources/account_unit_datasource.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

/// Account Unit Repository Implementation (Infrastructure Layer)
///
/// Delegates all storage operations to the data source.
/// No business logic - that belongs in use cases.
class AccountUnitRepositoryImpl implements AccountUnitRepository {
  final AccountUnitDataSource _dataSource;

  const AccountUnitRepositoryImpl(this._dataSource);

  @override
  Future<Result<void>> setAccountUnit(AccountUnit unit) async {
    try {
      return await _dataSource.setAccountUnit(unit);
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
      return await _dataSource.getAccountUnit();
    } catch (e) {
      return Failure(
        'Erro ao obter a unidade de conta: ${e.toString()}',
        e as Exception?,
      );
    }
  }
}
