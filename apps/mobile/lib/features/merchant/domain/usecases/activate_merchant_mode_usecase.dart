import 'package:mooze_mobile/features/merchant/domain/repositories/merchant_mode_repository.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

class ActivateMerchantModeUseCase {
  final MerchantModeRepository _repository;

  const ActivateMerchantModeUseCase(this._repository);

  /// Activates merchant mode
  ///
  /// Parameters:
  ///   - origin: Route to return to when exiting (defaults to '/home')
  Future<Result<void>> call({String origin = '/home'}) async {
    return await _repository.setMerchantModeActive(true, origin: origin);
  }
}
