import 'package:fpdart/fpdart.dart';

/// Abstracts device biometric and device-credential authentication.
///
/// Kept in the shared/authentication layer so both the setup flow and the
/// verify-PIN screen can share the same contract without depending on the
/// concrete local_auth package.
abstract class BiometricService {
  /// Returns true if the device has biometric hardware or a device credential
  /// (PIN / pattern / password) that can be used as fallback.
  Task<bool> isAvailable();

  /// Triggers the native biometric / device-credential prompt.
  ///
  /// Returns Right(true) on success, Right(false) if the user dismissed the
  /// prompt without authenticating, and Left(message) if a platform error
  /// prevented the prompt from appearing at all.
  TaskEither<String, bool> authenticate({required String reason});

  /// Returns true if the user has opted-in to biometric authentication.
  Task<bool> isEnabled();

  /// Persists whether biometric authentication is enabled.
  TaskEither<String, Unit> setEnabled(bool enabled);
}
