import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/features/settings/presentation/providers/security_settings_provider.dart';

import 'auth_prompt_controller.dart';
import 'privacy_shield_state.dart';

/// Owns the app-switcher privacy shield — the branded opaque cover that hides
/// wallet content while the app is inactive/backgrounded.
///
/// Deliberately minimal and dependency-light so it can render in the very first
/// lifecycle frame:
///   - no authentication, no VerifyPinScreen, no secure storage;
///   - the only providers it reads ([privacyShieldEnabledProvider],
///     [sessionLockEnabledProvider]) are synchronous SharedPreferences-backed
///     `Notifier<bool>`s, so [onLeavingForeground] resolves and flips state
///     within a single synchronous callback.
///
/// Separation of concerns: this controller decides *whether to cover*; the
/// [SessionLockController] independently decides *whether to require auth*. The
/// [SessionLockGate] combines the two.
class PrivacyShieldController extends Notifier<PrivacyShieldState> {
  @override
  PrivacyShieldState build() => PrivacyShieldState.hidden;

  /// Raises the shield the instant the app starts leaving the foreground
  /// (`inactive`), before the OS captures its app-switcher snapshot.
  ///
  /// The shield goes up when EITHER:
  ///   - the user enabled "Protect App Switcher", OR
  ///   - the session lock is enabled — because the lock relies on an
  ///     already-painted opaque cover to guarantee zero content flash when it
  ///     escalates to the auth UI on resume. (So enabling the lock implicitly
  ///     protects the switcher; the standalone toggle additionally protects it
  ///     when the lock is off.)
  void onLeavingForeground() {
    // A native biometric / device-credential prompt backgrounds the Flutter
    // view exactly like the app switcher does, firing `inactive`. That is NOT a
    // real backgrounding — raising the shield over the auth UI would hide the
    // "Use PIN" fallback (and, on a remount, loop biometrics). Skip it.
    if (ref.read(authPromptActiveProvider)) return;

    final privacyShieldEnabled = ref.read(privacyShieldEnabledProvider);
    final sessionLockEnabled = ref.read(sessionLockEnabledProvider);
    if (privacyShieldEnabled || sessionLockEnabled) {
      state = PrivacyShieldState.visible;
    }
  }

  /// Drops the shield on resume.
  ///
  /// Unconditional: the shield itself never gates the user. If the session has
  /// also expired, the [SessionLockController] flips to `locked` in the same
  /// resume and the [SessionLockGate] keeps an (auth) cover up regardless — so
  /// dropping the shield here never exposes content.
  void onResumed() => state = PrivacyShieldState.hidden;
}

final privacyShieldControllerProvider =
    NotifierProvider<PrivacyShieldController, PrivacyShieldState>(
      PrivacyShieldController.new,
    );
