import 'package:shared_preferences/shared_preferences.dart';

class UserLevelStorageService {
  static const String _verificationLevelKey = 'user_verification_level';

  final SharedPreferences _prefs;

  UserLevelStorageService(this._prefs);

  Future<void> saveVerificationLevel(int level) async {
    await _prefs.setInt(_verificationLevelKey, level);
  }
  int? getStoredVerificationLevel() {
    return _prefs.getInt(_verificationLevelKey);
  }

  Future<void> clearVerificationLevel() async {
    await _prefs.remove(_verificationLevelKey);
  }
}
