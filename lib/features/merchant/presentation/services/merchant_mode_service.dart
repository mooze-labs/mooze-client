import 'package:shared_preferences/shared_preferences.dart';

class MerchantModeService {
  static const String _merchantModeActiveKey = 'merchant_mode_active';
  static const String _merchantModeOriginKey = 'merchant_mode_origin';

  Future<bool> isMerchantModeActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_merchantModeActiveKey) ?? false;
  }

  Future<void> setMerchantModeActive(
    bool active, {
    String origin = '/home',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_merchantModeActiveKey, active);
    if (active) {
      await prefs.setString(_merchantModeOriginKey, origin);
    }
  }

  Future<String> getMerchantModeOrigin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_merchantModeOriginKey) ?? '/home';
  }

  Future<void> clearMerchantMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_merchantModeActiveKey);
    await prefs.remove(_merchantModeOriginKey);
  }
}
