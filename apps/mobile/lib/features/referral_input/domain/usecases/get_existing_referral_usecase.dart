import 'package:mooze_mobile/features/referral_input/domain/repositories/referral_repository.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

/// Use Case: Get Existing Referral
///
/// Retrieves the referral code currently applied to the user's account.
/// Returns null if no referral code has been applied.
class GetExistingReferralUseCase {
  final ReferralRepository _repository;

  const GetExistingReferralUseCase(this._repository);

  /// Returns: Result<String?> - the existing referral code, or null if none
  Future<Result<String?>> call() async {
    return await _repository.getExistingReferral();
  }
}
