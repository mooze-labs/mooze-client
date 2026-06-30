import 'package:mooze_mobile/features/settings/domain/entities/account_unit.dart';
import 'package:mooze_mobile/features/settings/domain/repositories/account_unit_repository.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

class SetAccountUnitUseCase {
  final AccountUnitRepository _repository;

  const SetAccountUnitUseCase(this._repository);

  /// Persists the user's preferred account unit
  Future<Result<void>> call(AccountUnit unit) async {
    return await _repository.setAccountUnit(unit);
  }
}
