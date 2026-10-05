import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:mooze_mobile/features/settings/domain/entities/session_lock_timeout.dart';
import 'package:mooze_mobile/shared/storage/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticationService {
  static const int maxPinAttemps = 5;

  final secureStorage = SecureStorageProvider.instance;

  Future<bool> isPinSetup() async {
    var hashedPin = await secureStorage.read(key: "hashedPin");
    return hashedPin != null;
  }

  Future<bool> createPin(String pin) async {
    if (pin.length < 4) {
      return false;
    }

    final String salt = _generateSalt();

    final bytes = utf8.encode("$pin$salt");
    final digest = sha256.convert(bytes);

    await secureStorage.write(key: "pinSalt", value: salt);
    await secureStorage.write(key: "hashedPin", value: digest.toString());

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("pinAttempts", 0);
    await _updateLastAuthTime();

    return true;
  }

  Future<bool> authenticate(String pin) async {
    // Session validity is intentionally not checked here — the bypass belongs
    // in VerifyPinScreen._checkSession(), which respects forceAuth. Checking it
    // here would let any wrong PIN succeed while a session is alive.
    var hashedPin = await secureStorage.read(key: "hashedPin");
    if (hashedPin == null) {
      throw Exception('No pin set');
    }

    var salt = await secureStorage.read(key: "pinSalt");
    if (salt == null) {
      throw Exception('No salt set');
    }

    var bytes = utf8.encode("$pin$salt");
    var digest = sha256.convert(bytes);

    bool success = digest.toString() == hashedPin;

    if (success) {
      await _updateLastAuthTime();
    }
    await _updateAttempts(success);
    return success;
  }

  /// Unconditionally clears the current session so the next app open always
  /// requires PIN entry.
  ///
  /// Must be called after any operation that changes the PIN so the old
  /// session cannot bypass the new PIN.
  Future<void> invalidateSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("lastAuthTime");
  }

  Future<bool> hasValidSession() async {
    final prefs = await SharedPreferences.getInstance();
    final lastAuthTime = prefs.getInt("lastAuthTime");

    if (lastAuthTime == null) {
      return false;
    }

    final lastAuth = DateTime.fromMillisecondsSinceEpoch(lastAuthTime);
    final diff = DateTime.now().difference(lastAuth);

    // Honour the user-configurable "Lock After" timeout. A zero duration means
    // any prior session is already invalid, so a cold open re-authenticates.
    return diff < SessionLockTimeout.fromPrefs(prefs).duration;
  }

  Future<int> getAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    var attempts = prefs.getInt("pinAttempts") ?? 0;
    return attempts;
  }

  Future<void> _updateAttempts(bool success) async {
    final prefs = await SharedPreferences.getInstance();
    var attempts = prefs.getInt("pinAttempts") ?? 0;

    if (!success) {
      await prefs.setInt("pinAttempts", attempts + 1);
    } else {
      await prefs.setInt("pinAttempts", 0);
    }
  }

  Future<void> _updateLastAuthTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("lastAuthTime", DateTime.now().millisecondsSinceEpoch);
  }

  String _generateSalt() {
    final secureRandom = SecureRandom(16);
    return base64Encode(secureRandom.bytes);
  }
}
