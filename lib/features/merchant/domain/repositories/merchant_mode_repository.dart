import 'package:mooze_mobile/shared/utils/result.dart';

/// Merchant Mode Repository Contract (Domain Layer)
///
/// Responsibilities:
/// - Check if merchant mode is currently active
/// - Activate/deactivate merchant mode
/// - Track the origin route (where user came from)
/// - Clear all merchant mode data

abstract class MerchantModeRepository {
  /// Checks if merchant mode is currently active
  /// Returns: Result<bool> - true if active, false otherwise
  Future<Result<bool>> isMerchantModeActive();

  /// Sets merchant mode activation state
  /// Parameters:
  ///   - active: true to activate, false to deactivate
  ///   - origin: the route to return to when exiting merchant mode
  /// Returns: Result<void> - Success or Failure with error message
  Future<Result<void>> setMerchantModeActive(bool active, {String origin});

  /// Gets the origin route (where user came from before entering merchant mode)
  Future<Result<String>> getMerchantModeOrigin();

  /// Clears all merchant mode data (resets state)
  Future<Result<void>> clearMerchantMode();
}
