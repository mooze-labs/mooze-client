import 'package:mooze_mobile/features/merchant/domain/repositories/merchant_mode_repository.dart';
import 'package:mooze_mobile/features/merchant/infra/datasources/merchant_mode_datasource.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

/// Merchant Mode Repository Implementation (Infrastructure Layer)
///
/// Implements the MerchantModeRepository interface from the domain layer.
/// Adapts data from the data source to the format expected by the domain.
///
/// Responsibilities:
/// - Delegates all storage operations to the data source
/// - Handles errors and wraps them in Result objects
/// - No business logic (that belongs in use cases)
/// - No knowledge of storage details (that's in the data source)
///
/// This class bridges the domain layer (business rules) and the
/// external layer (actual storage implementation).
class MerchantModeRepositoryImpl implements MerchantModeRepository {
  final MerchantModeDataSource _dataSource;

  const MerchantModeRepositoryImpl(this._dataSource);

  @override
  Future<Result<bool>> isMerchantModeActive() async {
    try {
      return await _dataSource.isActive();
    } catch (e) {
      return Failure(
        'Error checking merchant mode: ${e.toString()}',
        e as Exception?,
      );
    }
  }

  @override
  Future<Result<void>> setMerchantModeActive(
    bool active, {
    String origin = '/home',
  }) async {
    try {
      return await _dataSource.setActive(active, origin: origin);
    } catch (e) {
      return Failure(
        'Error setting merchant mode: ${e.toString()}',
        e as Exception?,
      );
    }
  }

  @override
  Future<Result<String>> getMerchantModeOrigin() async {
    try {
      return await _dataSource.getOrigin();
    } catch (e) {
      return Failure('Error getting origin: ${e.toString()}', e as Exception?);
    }
  }

  @override
  Future<Result<void>> clearMerchantMode() async {
    try {
      return await _dataSource.clear();
    } catch (e) {
      return Failure(
        'Error clearing merchant mode: ${e.toString()}',
        e as Exception?,
      );
    }
  }
}
