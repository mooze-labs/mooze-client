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

/// Typed authentication failure surface.
///
/// `code` mirrors the platform code where one exists — `PlatformException.code`
/// from local_auth ("NotAvailable", "NotEnrolled", "LockedOut", etc.) or the
/// native-bridge error codes from the Android device-credential flow
/// ("NO_DEVICE_CREDENTIAL", "BIOMETRIC_ERROR_*"). Keep the code stable across
/// versions so the UI layer can branch on it without parsing messages.
class AuthError {
  final String code;
  final String message;

  const AuthError({required this.code, required this.message});

  @override
  String toString() => '[$code] $message';
}

/// Abstracts device biometric and device-credential authentication.
///
/// Two semantically distinct operations are surfaced as separate methods on
/// purpose. The previous `authenticate({biometricOnly: bool})` was a boolean
/// trap that several call sites used incorrectly (e.g. confirming biometric
/// enrollment by accepting a device-PIN entry).
///
///   - [unlockWithBiometric] is for "the user has biometric enabled — prove
///     it's them right now using Face ID / Touch ID / fingerprint." It MUST
///     NOT fall back to device credential.
///   - [unlockWithDeviceCredential] is for the explicit recovery path — "I
///     forgot my app PIN, let me re-auth with the device PIN/pattern/password,
///     biometric optional." On Android this goes through a native bridge that
///     uses BIOMETRIC_WEAK | DEVICE_CREDENTIAL (the only mask documented to
///     work on API 28-29) and falls through to KeyguardManager directly when
///     the OEM prompt cannot honor the request — fixing the Xiaomi / MIUI /
///     HyperOS silent-failure path that `local_auth` cannot work around.
abstract class BiometricService {
  /// Returns true if the device has biometric hardware or a device credential
  /// (PIN / pattern / password) that can be used as fallback.
  Task<bool> isAvailable();

  /// Full capability report — what biometrics are enrolled vs. only device
  /// credential. Use this to drive UI that should only auto-trigger Face ID /
  /// Touch ID when biometrics are actually enrolled.
  Task<BiometricCapabilities> capabilities();

  /// Biometric-only authentication. Will never fall back to device PIN.
  ///
  /// Returns `Right(true)` on success, `Right(false)` if the user dismissed
  /// the prompt, and `Left(AuthError)` if a platform error prevented the
  /// prompt from appearing.
  TaskEither<AuthError, bool> unlockWithBiometric({required String reason});

  /// Device-credential authentication (with optional biometric).
  ///
  /// On Android, routed through the native bridge with
  /// `BIOMETRIC_WEAK | DEVICE_CREDENTIAL` and a KeyguardManager fallback. On
  /// iOS, uses `LAPolicy.deviceOwnerAuthentication`.
  ///
  /// Intended only for the recovery / "forgot PIN" flow. Do NOT use as the
  /// primary unlock — device credential is not equivalent to the app PIN as
  /// an authentication factor.
  TaskEither<AuthError, bool> unlockWithDeviceCredential({
    required String reason,
    String? title,
    String? subtitle,
  });

  /// Returns true if the user has opted-in to biometric authentication.
  Task<bool> isEnabled();

  /// Persists whether biometric authentication is enabled.
  TaskEither<String, Unit> setEnabled(bool enabled);
}
