import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'biometric_service.dart';

const _biometricEnabledKey = 'biometric_auth_enabled';

class BiometricServiceImpl implements BiometricService {
  final LocalAuthentication _localAuth;

  BiometricServiceImpl({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  @override
  Task<bool> isAvailable() {
    return Task(() async {
      try {
        final canCheck = await _localAuth.canCheckBiometrics;
        final isSupported = await _localAuth.isDeviceSupported();
        // The device is usable if it supports any strong authentication
        // (biometrics or device credential fallback).
        return canCheck || isSupported;
      } on PlatformException {
        return false;
      }
    });
  }

  @override
  TaskEither<String, bool> authenticate({required String reason}) {
    return TaskEither.tryCatch(
      () => _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          // Allow device PIN/pattern/password as fallback so users without
          // enrolled biometrics can still authenticate.
          biometricOnly: false,
        ),
      ),
      (error, _) {
        if (error is PlatformException) {
          return error.message ?? 'Erro de autenticação biométrica';
        }
        return error.toString();
      },
    );
  }

  @override
  Task<bool> isEnabled() {
    return Task(() async {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_biometricEnabledKey) ?? false;
    });
  }

  @override
  TaskEither<String, Unit> setEnabled(bool enabled) {
    return TaskEither.tryCatch(
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_biometricEnabledKey, enabled);
        return unit;
      },
      (error, _) => error.toString(),
    );
  }
}
