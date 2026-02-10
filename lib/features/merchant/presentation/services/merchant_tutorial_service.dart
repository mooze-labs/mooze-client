import 'package:shared_preferences/shared_preferences.dart';

class MerchantTutorialService {
  static const String _tutorialShownKey = 'merchant_tutorial_shown';

  Future<bool> isTutorialShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tutorialShownKey) ?? false;
  }

  Future<void> setTutorialShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialShownKey, true);
  }

  Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tutorialShownKey);
  }
}
