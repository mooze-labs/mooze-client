import 'package:mooze_mobile/features/settings/domain/entities/account_unit.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

/// Account Unit Data Source Contract (Infrastructure Layer)
abstract class AccountUnitDataSource {
  /// Persists the selected account unit
  Future<Result<void>> setAccountUnit(AccountUnit unit);

  /// Retrieves the stored account unit
  Future<Result<AccountUnit>> getAccountUnit();
}
