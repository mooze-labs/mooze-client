import 'package:mooze_mobile/shared/utils/result.dart';

/// Referral Repository Contract (Domain Layer)
///
/// Defines the operations available for referral code management.
/// Implemented in the infrastructure layer.
abstract class ReferralRepository {
  /// Retrieves the user's existing referral code, if any
  /// Returns: Result<String?> - the referral code or null if none applied
  Future<Result<String?>> getExistingReferral();

  /// Validates whether a referral code is valid
  /// Returns: Result<bool> - true if valid, false otherwise
  Future<Result<bool>> validateReferralCode(String code);

  /// Applies a referral code to the user's account
  /// Returns: Result<void> - Success or Failure with error message
  Future<Result<void>> applyReferralCode(String code);
}
