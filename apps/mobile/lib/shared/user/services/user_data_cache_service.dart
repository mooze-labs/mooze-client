import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../entities.dart';

/// Keeps the last answer of `/users/me`: the level, the progress, and the
/// limits of the user.
///
/// The level screen and the limits then open with it at once, and the
/// answer of the API replaces it in the background. It holds no secret:
/// the same values show on screen. The wallet cleanup clears it, so a new
/// wallet never shows the level of the old one.
class UserDataCacheService {
  static const String _userKey = 'user_data_cache';

  final SharedPreferences _prefs;

  UserDataCacheService(this._prefs);

  /// The saved user, or null when there is none or it no longer reads.
  User? read() {
    final raw = _prefs.getString(_userKey);
    if (raw == null) return null;
    try {
      return User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Saves [json], an answer of `/users/me`.
  Future<void> save(Map<String, dynamic> json) async {
    await _prefs.setString(_userKey, jsonEncode(json));
  }

  Future<void> clear() async {
    await _prefs.remove(_userKey);
  }
}
