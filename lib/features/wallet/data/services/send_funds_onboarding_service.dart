import 'package:shared_preferences/shared_preferences.dart';

class SendFundsOnboardingService {
  static const String _sendFundsFirstTimeDialogKey =
      'send_funds_lbtc_disclaimer_shown';

  final SharedPreferences _prefs;

  SendFundsOnboardingService(this._prefs);

  /// Checks if the user has already seen the L-BTC fee disclaimer on the Send screen
  bool hasSeenFirstTimeDialog() {
    return _prefs.getBool(_sendFundsFirstTimeDialogKey) ?? false;
  }

  /// Marks that the user has already seen and accepted the L-BTC fee disclaimer
  Future<void> markFirstTimeDialogAsSeen() async {
    await _prefs.setBool(_sendFundsFirstTimeDialogKey, true);
  }

  /// Resets the dialog state (useful for tests or re-showing the disclaimer)
  Future<void> resetFirstTimeDialog() async {
    await _prefs.remove(_sendFundsFirstTimeDialogKey);
  }
}
