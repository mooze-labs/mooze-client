import 'package:mooze_mobile/shared/utils/result.dart';

/// Referral Data Source Contract (Infrastructure Layer)
///
/// Defines the data access operations for referral code management.
/// Implemented in the external layer with the specific data source
/// (REST API, local storage, etc.).
abstract class ReferralDataSource {
  /// Retrieves the user's existing referral code
  Future<Result<String?>> getExistingReferral();

  /// Validates a referral code against the API
  Future<Result<bool>> validateReferralCode(String code);

  /// Applies a referral code to the user's account
  Future<Result<void>> applyReferralCode(String code);
}
