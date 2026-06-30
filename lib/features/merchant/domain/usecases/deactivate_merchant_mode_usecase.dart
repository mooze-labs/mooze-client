import 'package:mooze_mobile/features/merchant/domain/repositories/merchant_mode_repository.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

/// Use Case: Deactivate Merchant Mode
///
/// Encapsulates the business logic for deactivating merchant mode.
/// This clears all merchant mode state including the active flag
/// and the saved origin route.
///

class DeactivateMerchantModeUseCase {
  final MerchantModeRepository _repository;

  const DeactivateMerchantModeUseCase(this._repository);
  Future<Result<void>> call() async {
    return await _repository.clearMerchantMode();
  }
}
