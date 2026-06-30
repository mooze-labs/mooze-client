import 'package:shared_preferences/shared_preferences.dart';

/// User-configurable grace period before a backgrounded session must
/// re-authenticate.
///
/// Each value carries both its [duration] (consumed by the lock decision) and a
/// stable [storageValue] (persisted in SharedPreferences). The storage value is
/// decoupled from the enum name so a rename never silently resets a user's
/// choice.
enum SessionLockTimeout {
  /// Lock on any real backgrounding — the most aggressive behavior.
  immediate(Duration.zero, 'immediate'),
  seconds15(Duration(seconds: 15), 'seconds15'),
  seconds30(Duration(seconds: 30), 'seconds30'),
  minute1(Duration(minutes: 1), 'minute1'),
  minutes5(Duration(minutes: 5), 'minutes5');

  const SessionLockTimeout(this.duration, this.storageValue);

  /// How long the app may stay backgrounded before a resume requires
  /// re-authentication.
  final Duration duration;

  /// Stable token persisted in SharedPreferences.
  final String storageValue;

  /// SharedPreferences key under which the selected timeout is stored. Shared
  /// between the settings provider (writer) and the readers so there is a
  /// single source of truth.
  static const String prefsKey = 'sessionLockTimeout';

  /// Default when the user has never chosen.
  static const SessionLockTimeout defaultValue = SessionLockTimeout.immediate;

  /// Resolves a persisted [storageValue] back to its enum, falling back to
  /// [defaultValue] for unknown / absent values.
  static SessionLockTimeout fromStorage(String? value) {
    for (final timeout in SessionLockTimeout.values) {
      if (timeout.storageValue == value) return timeout;
    }
    return defaultValue;
  }

  /// Convenience reader for callers that already hold a [SharedPreferences]
  /// instance (e.g. [AuthenticationService.hasValidSession]).
  static SessionLockTimeout fromPrefs(SharedPreferences prefs) =>
      fromStorage(prefs.getString(prefsKey));
}
