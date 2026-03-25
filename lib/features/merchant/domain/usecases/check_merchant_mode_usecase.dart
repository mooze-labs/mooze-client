import 'package:mooze_mobile/features/merchant/domain/repositories/merchant_mode_repository.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

class CheckMerchantModeUseCase {
  final MerchantModeRepository _repository;

  const CheckMerchantModeUseCase(this._repository);

  /// Checks if merchant mode is currently active
  /// Returns: Result<bool> - true if active, false otherwise
  Future<Result<bool>> call() async {
    return await _repository.isMerchantModeActive();
  }
}
