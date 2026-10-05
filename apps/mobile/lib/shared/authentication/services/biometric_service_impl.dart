import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'biometric_service.dart';

const _biometricEnabledKey = 'biometric_auth_enabled';

/// Method channel that mirrors the Kotlin `CredentialAuthBridge`. Only used on
/// Android — on iOS the local_auth `LAPolicy.deviceOwnerAuthentication` path
/// already does the right thing.
const _credentialChannel = MethodChannel('com.mooze.auth/credential');

class BiometricServiceImpl implements BiometricService {
  final LocalAuthentication _localAuth;
  final MethodChannel _credentialBridge;

  BiometricServiceImpl({
    LocalAuthentication? localAuth,
    MethodChannel? credentialBridge,
  })  : _localAuth = localAuth ?? LocalAuthentication(),
        _credentialBridge = credentialBridge ?? _credentialChannel;

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
  TaskEither<AuthError, bool> unlockWithBiometric({required String reason}) {
    return TaskEither.tryCatch(
      () => _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          // Sticky-auth is safe here: only the biometric dialog briefly
          // backgrounds the activity. Avoid it on the device-credential flow
          // because the keyguard intent triggers a real activity pause.
          stickyAuth: true,
          biometricOnly: true,
        ),
      ),
      _mapPlatformError,
    );
  }

  @override
  TaskEither<AuthError, bool> unlockWithDeviceCredential({
    required String reason,
    String? title,
    String? subtitle,
  }) {
    if (Platform.isAndroid) {
      return _androidUnlockWithDeviceCredential(
        reason: reason,
        title: title,
        subtitle: subtitle,
      );
    }
    return _iosUnlockWithDeviceCredential(reason: reason);
  }

  TaskEither<AuthError, bool> _androidUnlockWithDeviceCredential({
    required String reason,
    String? title,
    String? subtitle,
  }) {
    return TaskEither.tryCatch(
      () async {
        final result = await _credentialBridge.invokeMethod<bool>(
          'authenticateWithCredential',
          {
            'reason': reason,
            'title': title ?? reason,
            if (subtitle != null) 'subtitle': subtitle,
          },
        );
        return result ?? false;
      },
      _mapPlatformError,
    );
  }

  TaskEither<AuthError, bool> _iosUnlockWithDeviceCredential({
    required String reason,
  }) {
    return TaskEither.tryCatch(
      () => _localAuth.authenticate(
        localizedReason: reason,
        // No stickyAuth: a passcode keyguard pauses the activity and stickyAuth
        // races with the resume to relaunch a stale prompt.
        options: const AuthenticationOptions(biometricOnly: false),
      ),
      _mapPlatformError,
    );
  }

  AuthError _mapPlatformError(Object error, StackTrace _) {
    if (error is PlatformException) {
      return AuthError(
        code: error.code,
        message: error.message ?? 'Authentication failed',
      );
    }
    return AuthError(code: 'UNKNOWN', message: error.toString());
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
