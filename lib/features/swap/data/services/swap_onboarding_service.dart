import 'package:shared_preferences/shared_preferences.dart';

class SwapOnboardingService {
  static const String _btcLbtcSwapWarningKey =
      'btc_lbtc_swap_warning_shown1123123';

  final SharedPreferences _prefs;

  SwapOnboardingService(this._prefs);

  bool hasSeenBtcLbtcSwapWarning() {
    return _prefs.getBool(_btcLbtcSwapWarningKey) ?? false;
  }

  Future<void> markBtcLbtcSwapWarningAsSeen() async {
    await _prefs.setBool(_btcLbtcSwapWarningKey, true);
  }

  Future<void> resetBtcLbtcSwapWarning() async {
    await _prefs.remove(_btcLbtcSwapWarningKey);
  }
}
