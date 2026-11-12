import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the user id that `/users/me` gives, which the support screen shows
/// as the support code.
///
/// The id never changes for a wallet, so one answer is enough. The support
/// screen then shows it at once, also offline or when the API refuses a
/// blocked account. It is not a secret: the user shares it with support.
/// The wallet cleanup clears it, so a new wallet never shows the id of the
/// old one.
class UserIdStorageService {
  static const String _userIdKey = 'user_support_id';

  final SharedPreferences _prefs;

  UserIdStorageService(this._prefs);

  String? read() => _prefs.getString(_userIdKey);

  Future<void> save(String id) async {
    if (read() == id) return;
    await _prefs.setString(_userIdKey, id);
  }

  Future<void> clear() async {
    await _prefs.remove(_userIdKey);
  }
}
