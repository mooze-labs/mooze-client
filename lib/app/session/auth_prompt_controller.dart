import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks whether a native authentication prompt (biometric / device
/// credential) is currently on screen.
///
/// Disambiguates the `inactive` lifecycle event: the OS biometric dialog
/// backgrounds the Flutter view like the app switcher does, but it is not a
/// real backgrounding. Callers bracket a prompt with [begin]/[end], and
/// [PrivacyShieldController.onLeavingForeground] skips raising the shield while
/// a prompt is active — otherwise it would hide the auth UI and loop biometrics.
class AuthPromptController extends Notifier<bool> {
  @override
  bool build() => false;

  void begin() => state = true;
  void end() => state = false;
}

final authPromptActiveProvider = NotifierProvider<AuthPromptController, bool>(
  AuthPromptController.new,
);
