import 'package:shared_preferences/shared_preferences.dart';
import 'package:mooze_mobile/features/merchant/infra/datasources/merchant_mode_datasource.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

/// Merchant Mode Local Data Source Implementation (External Layer)
///
/// Storage Keys:
/// - 'merchant_mode_active': boolean flag for activation status
/// - 'merchant_mode_origin': string storing the return route
///
/// To switch storage (e.g., to secure storage or remote API),
/// simply create a new implementation of MerchantModeDataSource
/// and update the provider - no other layers need to change.
class MerchantModeLocalDataSource implements MerchantModeDataSource {
  /// Key for storing merchant mode activation status
  static const String _merchantModeActiveKey = 'merchant_mode_active';

  /// Key for storing the origin route
  static const String _merchantModeOriginKey = 'merchant_mode_origin';

  @override
  Future<Result<bool>> isActive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isActive = prefs.getBool(_merchantModeActiveKey) ?? false;
      return Success(isActive);
    } catch (e) {
      return Failure('Error checking status: ${e.toString()}', e as Exception?);
    }
  }

  @override
  Future<Result<void>> setActive(bool active, {String origin = '/home'}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_merchantModeActiveKey, active);
      // Save origin route when activating
      if (active) {
        await prefs.setString(_merchantModeOriginKey, origin);
      }
      return const Success(null);
    } catch (e) {
      return Failure('Error setting status: ${e.toString()}', e as Exception?);
    }
  }

  @override
  Future<Result<String>> getOrigin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final origin = prefs.getString(_merchantModeOriginKey) ?? '/home';
      return Success(origin);
    } catch (e) {
      return Failure('Error getting origin: ${e.toString()}', e as Exception?);
    }
  }

  @override
  Future<Result<void>> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Remove both keys to completely reset merchant mode state
      await prefs.remove(_merchantModeActiveKey);
      await prefs.remove(_merchantModeOriginKey);
      return const Success(null);
    } catch (e) {
      return Failure(
        'Error clearing settings: ${e.toString()}',
        e as Exception?,
      );
    }
  }
}
