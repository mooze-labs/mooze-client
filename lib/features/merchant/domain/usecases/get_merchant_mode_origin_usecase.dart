import 'package:mooze_mobile/features/merchant/domain/repositories/merchant_mode_repository.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

class GetMerchantModeOriginUseCase {
  final MerchantModeRepository _repository;

  const GetMerchantModeOriginUseCase(this._repository);

  Future<Result<String>> call() async {
    return await _repository.getMerchantModeOrigin();
  }
}
