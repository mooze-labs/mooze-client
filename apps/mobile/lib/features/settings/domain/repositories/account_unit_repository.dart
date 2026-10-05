import 'package:mooze_mobile/features/settings/domain/entities/account_unit.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

/// Account Unit Repository Contract (Domain Layer)
///
/// Defines operations for persisting and retrieving
/// the user's preferred account unit (satoshi or bitcoin).
abstract class AccountUnitRepository {
  /// Persists the selected account unit
  Future<Result<void>> setAccountUnit(AccountUnit unit);

  /// Retrieves the current account unit setting
  /// Returns satoshi as default when no value is stored
  Future<Result<AccountUnit>> getAccountUnit();
}
