import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mooze_mobile/features/settings/domain/entities/session_lock_timeout.dart';
import 'package:mooze_mobile/features/settings/presentation/providers/security_settings_provider.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';

Future<ProviderContainer> _container(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('security settings providers', () {
    test('default: lock and shield enabled, immediate timeout', () async {
      final container = await _container({});
      expect(container.read(sessionLockEnabledProvider), isTrue);
      expect(container.read(privacyShieldEnabledProvider), isTrue);
      expect(
        container.read(sessionLockTimeoutProvider),
        SessionLockTimeout.immediate,
      );
    });

    test('reads persisted values', () async {
      final container = await _container({
        'sessionLockEnabled': false,
        'privacyShieldEnabled': false,
        SessionLockTimeout.prefsKey: SessionLockTimeout.minutes5.storageValue,
      });
      expect(container.read(sessionLockEnabledProvider), isFalse);
      expect(container.read(privacyShieldEnabledProvider), isFalse);
      expect(
        container.read(sessionLockTimeoutProvider),
        SessionLockTimeout.minutes5,
      );
    });

    test('setTimeout persists and updates state', () async {
      final container = await _container({});
      await container
          .read(sessionLockTimeoutProvider.notifier)
          .setTimeout(SessionLockTimeout.seconds30);

      expect(
        container.read(sessionLockTimeoutProvider),
        SessionLockTimeout.seconds30,
      );
      final sp = await SharedPreferences.getInstance();
      expect(
        sp.getString(SessionLockTimeout.prefsKey),
        SessionLockTimeout.seconds30.storageValue,
      );
    });

    test('toggles persist and update state', () async {
      final container = await _container({});
      await container
          .read(sessionLockEnabledProvider.notifier)
          .setEnabled(false);
      await container
          .read(privacyShieldEnabledProvider.notifier)
          .setEnabled(false);

      expect(container.read(sessionLockEnabledProvider), isFalse);
      expect(container.read(privacyShieldEnabledProvider), isFalse);
    });

    test('unknown stored timeout falls back to default', () async {
      final container = await _container({
        SessionLockTimeout.prefsKey: 'bogus-value',
      });
      expect(
        container.read(sessionLockTimeoutProvider),
        SessionLockTimeout.defaultValue,
      );
    });
  });
}
