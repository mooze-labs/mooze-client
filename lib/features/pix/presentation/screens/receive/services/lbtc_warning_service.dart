import 'package:shared_preferences/shared_preferences.dart';

class LbtcWarningService {
  static const String _warningShownKey = 'lbtc_fluctuation_warning_shown';

  Future<bool> isWarningShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_warningShownKey) ?? false;
  }

  Future<void> setWarningShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_warningShownKey, true);
  }

  Future<void> resetWarning() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_warningShownKey);
  }
}
