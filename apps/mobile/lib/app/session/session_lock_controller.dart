import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/features/merchant/external/datasources/merchant_mode_local_datasource.dart';
import 'package:mooze_mobile/features/settings/presentation/providers/security_settings_provider.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';

import 'auth_prompt_controller.dart';
import 'session_lock_state.dart';

/// Decides whether returning to the foreground requires re-authentication.
///
/// Concerned only with the auth decision — covering the screen is the privacy
/// shield's job. All transitions are synchronous so the decision is committed
/// before the first foreground frame. Gated by the user's "Use Biometric/PIN
/// Lock" preference and the configurable "Lock After" timeout, both read
/// synchronously from the settings providers.
class SessionLockController extends Notifier<SessionLockState> {
  /// When the app last truly backgrounded (`paused` / `hidden`). In-memory only;
  /// a cold start is gated by the splash → verify-PIN flow instead. Distinct
  /// from a transient `inactive` so a glance at control center never starts the
  /// lock timer.
  DateTime? _backgroundedAt;

  /// Test-only override for the configured timeout, so the within-window branch
  /// can be exercised without seeding prefs. Null in production (the value is
  /// read from [sessionLockTimeoutProvider]).
  Duration? _timeoutOverride;

  @override
  SessionLockState build() => SessionLockState.unlocked;

  bool get _enabled => ref.read(sessionLockEnabledProvider);

  bool get _isMerchant =>
      ref
          .read(sharedPreferencesProvider)
          .getBool(MerchantModeLocalDataSource.merchantModeActiveKey) ??
      false;

  Duration get _timeout =>
      _timeoutOverride ?? ref.read(sessionLockTimeoutProvider).duration;

  /// Records the moment the app truly backgrounded. Called on `paused` /
  /// `hidden` only.
  void onBackgrounded() {
    if (!_enabled) return;
    if (state == SessionLockState.locked) return;
    // A native auth prompt backgrounds the app on some platforms (notably
    // Android, where BiometricPrompt fires `paused`). That is not a real
    // backgrounding — recording it would lock the session the instant the
    // prompt is dismissed.
    if (ref.read(authPromptActiveProvider)) return;
    _backgroundedAt = DateTime.now();
  }

  /// Resolves the lock on resume, synchronously, before the first foreground
  /// frame.
  void onResumed() {
    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;

    if (state == SessionLockState.locked) return;

    // Lock disabled, merchant mode, or never actually backgrounded → no auth.
    if (!_enabled || _isMerchant || backgroundedAt == null) {
      state = SessionLockState.unlocked;
      return;
    }

    if (DateTime.now().difference(backgroundedAt) >= _timeout) {
      state = SessionLockState.locked;
    } else {
      state = SessionLockState.unlocked;
    }
  }

  /// Clears the lock after the embedded verify-PIN flow authenticates.
  void unlock() => state = SessionLockState.unlocked;

  /// Seeds the in-memory background timestamp directly so the timeout branch of
  /// [onResumed] can be exercised deterministically in tests.
  @visibleForTesting
  void debugSetBackgroundedAt(DateTime instant) => _backgroundedAt = instant;

  /// Overrides the configured timeout for tests.
  @visibleForTesting
  set debugTimeout(Duration value) => _timeoutOverride = value;
}

final sessionLockControllerProvider =
    NotifierProvider<SessionLockController, SessionLockState>(
      SessionLockController.new,
    );
