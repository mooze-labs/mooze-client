import 'package:mooze_mobile/features/settings/domain/entities/account_unit.dart';
import 'package:mooze_mobile/features/settings/domain/repositories/account_unit_repository.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

class GetAccountUnitUseCase {
  final AccountUnitRepository _repository;

  const GetAccountUnitUseCase(this._repository);

  /// Retrieves the user's preferred account unit
  Future<Result<AccountUnit>> call() async {
    return await _repository.getAccountUnit();
  }
}
