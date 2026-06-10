import 'package:shared_preferences/shared_preferences.dart';

class PixTutorialService {
  static const String _tutorialShownKey = 'hasSeenPixTutorial';

  final SharedPreferences _prefs;

  PixTutorialService(this._prefs);

  bool isTutorialShown() {
    return _prefs.getBool(_tutorialShownKey) ?? false;
  }

  Future<void> setTutorialShown() async {
    await _prefs.setBool(_tutorialShownKey, true);
  }

  Future<void> resetTutorial() async {
    await _prefs.remove(_tutorialShownKey);
  }
}
