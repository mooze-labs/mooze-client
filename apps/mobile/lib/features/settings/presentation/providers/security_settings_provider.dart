import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/features/settings/domain/entities/session_lock_timeout.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';

/// Security preferences, persisted via SharedPreferences and read synchronously
/// in `build()`. Synchronous reads matter: the privacy shield and session lock
/// consult these providers from inside lifecycle callbacks and must decide
/// within a single frame. `sharedPreferencesProvider` is overridden at startup
/// with an already-loaded instance, so the reads never block.

/// Master switch for the session lock — "Use Biometric/PIN Lock". When off,
/// returning to the foreground never requires re-authentication.
class SessionLockEnabledNotifier extends Notifier<bool> {
  static const _key = 'sessionLockEnabled';

  @override
  bool build() {
    // Default ON: preserve the historical re-authenticate-on-resume behavior
    // for existing users who never visit the new screen.
    return ref.read(sharedPreferencesProvider).getBool(_key) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    await ref.read(sharedPreferencesProvider).setBool(_key, enabled);
    state = enabled;
  }
}

final sessionLockEnabledProvider =
    NotifierProvider<SessionLockEnabledNotifier, bool>(
      SessionLockEnabledNotifier.new,
    );

/// "Protect App Switcher" — whether the branded privacy shield covers the app
/// while it is inactive/backgrounded. Independent of the session lock.
class PrivacyShieldEnabledNotifier extends Notifier<bool> {
  static const _key = 'privacyShieldEnabled';

  @override
  bool build() {
    // Default ON: the safe default for a wallet.
    return ref.read(sharedPreferencesProvider).getBool(_key) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    await ref.read(sharedPreferencesProvider).setBool(_key, enabled);
    state = enabled;
  }
}

final privacyShieldEnabledProvider =
    NotifierProvider<PrivacyShieldEnabledNotifier, bool>(
      PrivacyShieldEnabledNotifier.new,
    );

/// "Lock After" — the grace period before a backgrounded session must
/// re-authenticate.
class SessionLockTimeoutNotifier extends Notifier<SessionLockTimeout> {
  @override
  SessionLockTimeout build() {
    return SessionLockTimeout.fromPrefs(ref.read(sharedPreferencesProvider));
  }

  Future<void> setTimeout(SessionLockTimeout timeout) async {
    await ref
        .read(sharedPreferencesProvider)
        .setString(SessionLockTimeout.prefsKey, timeout.storageValue);
    state = timeout;
  }
}

final sessionLockTimeoutProvider =
    NotifierProvider<SessionLockTimeoutNotifier, SessionLockTimeout>(
      SessionLockTimeoutNotifier.new,
    );
