import 'package:fpdart/fpdart.dart';

/// Capabilities of the device's native authentication subsystem.
///
/// Distinguishes between "biometric is actually enrolled" (Face ID, Touch ID,
/// fingerprint) and the weaker case where only a device credential
/// (PIN/pattern/password) is set up. This lets callers prefer biometrics on
/// iOS where missing this distinction caused the system to skip Face ID and
/// jump straight to the passcode prompt.
class BiometricCapabilities {
  /// True if the device has at least one biometric enrolled (Face ID, Touch
  /// ID, fingerprint, etc.).
  final bool hasBiometrics;

  /// True if the device has any form of secure authentication available —
  /// biometric OR device credential.
  final bool hasAnyAuth;

  /// True if Face ID specifically is available on the device.
  final bool hasFaceId;

  /// True if Touch ID / fingerprint is available on the device.
  final bool hasFingerprint;

  const BiometricCapabilities({
    required this.hasBiometrics,
    required this.hasAnyAuth,
    required this.hasFaceId,
    required this.hasFingerprint,
  });

  static const none = BiometricCapabilities(
    hasBiometrics: false,
    hasAnyAuth: false,
    hasFaceId: false,
    hasFingerprint: false,
  );
}

/// Abstracts device biometric and device-credential authentication.
///
/// Kept in the shared/authentication layer so both the setup flow and the
/// verify-PIN screen can share the same contract without depending on the
/// concrete local_auth package.
abstract class BiometricService {
  /// Returns true if the device has biometric hardware or a device credential
  /// (PIN / pattern / password) that can be used as fallback.
  Task<bool> isAvailable();

  /// Full capability report — what biometrics are enrolled vs. only device
  /// credential. Use this to drive UI that should only auto-trigger Face ID /
  /// Touch ID when biometrics are actually enrolled.
  Task<BiometricCapabilities> capabilities();

  /// Triggers the native biometric / device-credential prompt.
  ///
  /// When [biometricOnly] is true, the platform will only accept enrolled
  /// biometrics (Face ID / Touch ID / fingerprint) and will NOT fall back to
  /// the device passcode. The verify-PIN screen uses this so the in-app PIN
  /// remains the only passcode fallback — avoiding the surprising UX where
  /// iOS skips Face ID entirely and asks for the device passcode.
  ///
  /// Returns Right(true) on success, Right(false) if the user dismissed the
  /// prompt without authenticating, and Left(message) if a platform error
  /// prevented the prompt from appearing at all.
  TaskEither<String, bool> authenticate({
    required String reason,
    bool biometricOnly = false,
  });

  /// Returns true if the user has opted-in to biometric authentication.
  Task<bool> isEnabled();

  /// Persists whether biometric authentication is enabled.
  TaskEither<String, Unit> setEnabled(bool enabled);
}
