import 'package:mooze_mobile/shared/utils/result.dart';

/// Merchant Mode Data Source Contract (Infrastructure Layer)

abstract class MerchantModeDataSource {
  /// Checks if merchant mode is currently active
  Future<Result<bool>> isActive();

  /// Sets the merchant mode activation state
  /// Parameters:
  ///   - active: true to activate, false to deactivate
  ///   - origin: the route to return to when exiting
  Future<Result<void>> setActive(bool active, {String origin});

  /// Gets the saved origin route
  Future<Result<String>> getOrigin();

  /// Clears all merchant mode data
  Future<Result<void>> clear();
}
