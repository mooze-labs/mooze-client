import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticationService {
  static const int maxPinAttemps = 5;
  static const int sessionTimeoutMinutes = 1;

  final secureStorage = FlutterSecureStorage();

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
    final isSessionValid = await hasValidSession();
    debugPrint("Session is considered valid: $isSessionValid");
    if (isSessionValid) {
      return true;
    }

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

    print("Digest: $digest");
    print("Hashed pin: $hashedPin");

    bool success = digest.toString() == hashedPin;
    print("Success: $success");

    if (success) {
      await _updateLastAuthTime();
    }
    await _updateAttempts(success);
    return success;
  }

  Future<void> invalidateSession() async {
    final prefs = await SharedPreferences.getInstance();
    final lastAuthTime = prefs.getInt("lastAuthTime");

    if (lastAuthTime == null) {
      return;
    }

    final lastAuth = DateTime.fromMillisecondsSinceEpoch(lastAuthTime);
    final diff = DateTime.now().difference(lastAuth);

    if (diff.inMinutes > sessionTimeoutMinutes) {
      await prefs.remove("lastAuthTime");
      return;
    }

    return;
  }

  Future<bool> hasValidSession() async {
    final prefs = await SharedPreferences.getInstance();
    final lastAuthTime = prefs.getInt("lastAuthTime");

    print("Last auth time: $lastAuthTime");

    if (lastAuthTime == null) {
      return false;
    }

    final lastAuth = DateTime.fromMillisecondsSinceEpoch(lastAuthTime);
    final diff = DateTime.now().difference(lastAuth);

    return diff.inMinutes < sessionTimeoutMinutes;
  }

  Future<int> getAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    var attempts = prefs.getInt("pinAttempts") ?? 0;
    return attempts;
  }

  Future<bool> _tooManyAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    var attempts = prefs.getInt("pinAttempts") ?? 0;
    if (attempts >= maxPinAttemps) {
      return true;
    }

    return false;
  }

  Future<void> _updateAttempts(bool success) async {
    final prefs = await SharedPreferences.getInstance();
    var attempts = prefs.getInt("pinAttempts") ?? 0;

    if (!success) {
      prefs.setInt("pinAttempts", attempts++);
    }

    //final exceededAttempts = await _tooManyAttempts();
    //if (exceededAttempts) {
    //  await secureStorage.deleteAll(); // deletes EVERYTHING
    //}

    await prefs.setInt("pinAttempts", 0);
    if (success) {
      await prefs.setInt("lastAuthTime", DateTime.now().millisecondsSinceEpoch);
    }
  }

  Future<void> _updateLastAuthTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("lastAuthTime", DateTime.now().millisecondsSinceEpoch);
    print("Updated auth time.");
  }

  String _generateSalt() {
    final secureRandom = SecureRandom(16);
    return base64Encode(secureRandom.bytes);
  }
}
