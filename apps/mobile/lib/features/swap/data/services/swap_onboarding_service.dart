import 'package:shared_preferences/shared_preferences.dart';

class SwapOnboardingService {
  /// Marks the BTC / L-BTC warning as seen. The `_v2` suffix came with the
  /// SideSwap text: the first text named Breez and a manual refund in the
  /// app, so a user who read it sees the new text once.
  static const String btcLbtcSwapWarningKey = 'btc_lbtc_swap_warning_shown_v2';

  final SharedPreferences _prefs;

  SwapOnboardingService(this._prefs);

  bool hasSeenBtcLbtcSwapWarning() {
    return _prefs.getBool(btcLbtcSwapWarningKey) ?? false;
  }

  Future<void> markBtcLbtcSwapWarningAsSeen() async {
    await _prefs.setBool(btcLbtcSwapWarningKey, true);
  }

  Future<void> resetBtcLbtcSwapWarning() async {
    await _prefs.remove(btcLbtcSwapWarningKey);
  }
}
