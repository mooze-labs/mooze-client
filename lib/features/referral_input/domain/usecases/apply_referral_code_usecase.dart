import 'package:mooze_mobile/features/referral_input/domain/repositories/referral_repository.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

/// Use Case: Apply Referral Code
///
/// Validates a referral code and applies it to the user's account.
/// Validation occurs before application to ensure data integrity.
///
/// Business Rules:
/// - Code cannot be empty
/// - Code must be validated against the API before application
/// - Only valid codes are applied to the account
class ApplyReferralCodeUseCase {
  final ReferralRepository _repository;

  const ApplyReferralCodeUseCase(this._repository);

  /// Validates and applies a referral code
  ///
  /// Parameters:
  ///   - code: The referral code to validate and apply
  /// Returns: Result<void> - Success or Failure with error message
  Future<Result<void>> call(String code) async {
    if (code.isEmpty) {
      return const Failure('referral_error_empty_code');
    }

    // Validate the code before applying
    final validationResult = await _repository.validateReferralCode(code);
    if (validationResult.isFailure) {
      return const Failure('referral_error_invalid_code');
    }

    final isValid = validationResult.data!;
    if (!isValid) {
      return const Failure('referral_error_invalid_code');
    }

    // Code is valid, apply it to the account
    final applyResult = await _repository.applyReferralCode(code);
    if (applyResult.isFailure) {
      return const Failure('referral_error_apply_failed');
    }

    return const Success(null);
  }
}
