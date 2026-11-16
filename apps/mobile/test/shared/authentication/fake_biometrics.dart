import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/shared/authentication/services/biometric_service.dart';

/// A device with Face ID.
const faceIdDevice = BiometricCapabilities(
  hasBiometrics: true,
  hasAnyAuth: true,
  hasFaceId: true,
  hasFingerprint: false,
);

/// A device with a fingerprint.
const fingerprintDevice = BiometricCapabilities(
  hasBiometrics: true,
  hasAnyAuth: true,
  hasFaceId: false,
  hasFingerprint: true,
);

/// A device with a passcode and no biometric.
const passcodeDevice = BiometricCapabilities(
  hasBiometrics: false,
  hasAnyAuth: true,
  hasFaceId: false,
  hasFingerprint: false,
);

/// Biometrics whose prompts the test settles by hand.
class FakeBiometrics implements BiometricService {
  FakeBiometrics(this.enrolled, {this.enabled = false});

  BiometricCapabilities enrolled;

  /// Whether the user unlocks with biometrics.
  bool enabled;

  /// One completer per prompt.
  final prompts = <Completer<Either<AuthError, bool>>>[];
  final saved = <bool>[];
  bool saveFails = false;

  @override
  TaskEither<AuthError, bool> unlockWithBiometric({required String reason}) {
    final prompt = Completer<Either<AuthError, bool>>();
    prompts.add(prompt);
    return TaskEither(() => prompt.future);
  }

  @override
  TaskEither<String, Unit> setEnabled(bool enabled) => TaskEither(() async {
    if (saveFails) return const Left('disk full');
    saved.add(enabled);
    this.enabled = enabled;
    return const Right(unit);
  });

  @override
  Task<BiometricCapabilities> capabilities() => Task.of(enrolled);

  @override
  Task<bool> isAvailable() => Task.of(enrolled.hasAnyAuth);

  @override
  Task<bool> isEnabled() => Task.of(enabled);

  @override
  TaskEither<AuthError, bool> unlockWithDeviceCredential({
    required String reason,
    String? title,
    String? subtitle,
  }) => throw UnimplementedError();
}
