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
        final caps = await _readCapabilities();
        return caps.hasAnyAuth;
      } on PlatformException {
        return false;
      }
    });
  }

  @override
  Task<BiometricCapabilities> capabilities() {
    return Task(() async {
      try {
        return await _readCapabilities();
      } on PlatformException {
        return BiometricCapabilities.none;
      }
    });
  }

  Future<BiometricCapabilities> _readCapabilities() async {
    final isSupported = await _localAuth.isDeviceSupported();
    if (!isSupported) return BiometricCapabilities.none;

    final canCheckBiometrics = await _localAuth.canCheckBiometrics;
    final enrolled = canCheckBiometrics
        ? await _localAuth.getAvailableBiometrics()
        : const <BiometricType>[];

    final hasFaceId = enrolled.contains(BiometricType.face);
    final hasFingerprint = enrolled.contains(BiometricType.fingerprint) ||
        enrolled.contains(BiometricType.strong) ||
        enrolled.contains(BiometricType.weak);

    return BiometricCapabilities(
      hasBiometrics: enrolled.isNotEmpty,
      // isDeviceSupported() returns true for any device-credential capable
      // platform, so we use it as the "any auth at all" signal.
      hasAnyAuth: true,
      hasFaceId: hasFaceId,
      hasFingerprint: hasFingerprint,
    );
  }

  @override
  TaskEither<String, bool> authenticate({
    required String reason,
    bool biometricOnly = false,
  }) {
    return TaskEither.tryCatch(
      () => _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          // Keep the prompt visible if the app is briefly backgrounded by the
          // system biometric dialog.
          stickyAuth: true,
          // When the caller wants biometrics specifically (the in-app unlock
          // flow), refuse to fall back to device passcode. The app's own PIN
          // is the secondary path.
          biometricOnly: biometricOnly,
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
