import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mooze_mobile/app/session/auth_prompt_controller.dart';
import 'package:mooze_mobile/app/session/session_lock_controller.dart';
import 'package:mooze_mobile/app/session/session_lock_state.dart';
import 'package:mooze_mobile/features/merchant/external/datasources/merchant_mode_local_datasource.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';

/// Two minutes in the past — comfortably beyond any timeout these tests use.
final _longAgo = DateTime.now().subtract(const Duration(minutes: 2));

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

  group('SessionLockController', () {
    test('starts unlocked', () async {
      final container = await _container({});
      expect(
        container.read(sessionLockControllerProvider),
        SessionLockState.unlocked,
      );
    });

    test('session lock disabled never locks, even after a long background',
        () async {
      final container = await _container({'sessionLockEnabled': false});
      final controller =
          container.read(sessionLockControllerProvider.notifier);

      controller.onBackgrounded(); // no-op when disabled
      controller.debugSetBackgroundedAt(_longAgo);
      controller.onResumed();

      expect(
        container.read(sessionLockControllerProvider),
        SessionLockState.unlocked,
      );
    });

    test('session lock enabled + timeout reached → locked', () async {
      // Default prefs: enabled, immediate timeout.
      final container = await _container({});
      final controller =
          container.read(sessionLockControllerProvider.notifier);

      controller.debugSetBackgroundedAt(_longAgo);
      controller.onResumed();

      expect(
        container.read(sessionLockControllerProvider),
        SessionLockState.locked,
      );
    });

    test('session lock enabled + timeout NOT reached → unlocked', () async {
      final container = await _container({});
      final controller =
          container.read(sessionLockControllerProvider.notifier);
      controller.debugTimeout = const Duration(minutes: 10);

      controller.onBackgrounded(); // timestamp = now
      controller.onResumed(); // elapsed ~0, under 10 min

      expect(
        container.read(sessionLockControllerProvider),
        SessionLockState.unlocked,
      );
    });

    test('a background during an active auth prompt does not lock on resume',
        () async {
      // Simulates Android's BiometricPrompt firing `paused`: the controller
      // must not treat it as a real backgrounding, otherwise dismissing the
      // prompt would lock the session and re-pop the lock overlay.
      final container = await _container({});
      final controller =
          container.read(sessionLockControllerProvider.notifier);

      container.read(authPromptActiveProvider.notifier).begin();
      controller.onBackgrounded(); // ignored while the prompt is active
      container.read(authPromptActiveProvider.notifier).end();
      controller.onResumed();

      expect(
        container.read(sessionLockControllerProvider),
        SessionLockState.unlocked,
      );
    });

    test('resume without a prior background never locks', () async {
      final container = await _container({});
      container.read(sessionLockControllerProvider.notifier).onResumed();
      expect(
        container.read(sessionLockControllerProvider),
        SessionLockState.unlocked,
      );
    });

    test('merchant mode never locks even when expired', () async {
      // Read straight from prefs (the datasource's source of truth) — no async
      // merchant controller needs to be alive for the terminal to stay unlocked.
      final container = await _container({
        MerchantModeLocalDataSource.merchantModeActiveKey: true,
      });

      final controller =
          container.read(sessionLockControllerProvider.notifier);
      controller.debugSetBackgroundedAt(_longAgo);
      controller.onResumed();

      expect(
        container.read(sessionLockControllerProvider),
        SessionLockState.unlocked,
      );
    });

    test('unlock clears the lock', () async {
      final container = await _container({});
      final controller =
          container.read(sessionLockControllerProvider.notifier);

      controller.debugSetBackgroundedAt(_longAgo);
      controller.onResumed();
      expect(
        container.read(sessionLockControllerProvider),
        SessionLockState.locked,
      );

      controller.unlock();
      expect(
        container.read(sessionLockControllerProvider),
        SessionLockState.unlocked,
      );
    });

    test('a background/resume cycle while locked stays locked', () async {
      final container = await _container({});
      final controller =
          container.read(sessionLockControllerProvider.notifier);

      controller.debugSetBackgroundedAt(_longAgo);
      controller.onResumed();
      expect(
        container.read(sessionLockControllerProvider),
        SessionLockState.locked,
      );

      controller.onBackgrounded(); // must not refresh the timer
      controller.onResumed(); // must not silently unlock
      expect(
        container.read(sessionLockControllerProvider),
        SessionLockState.locked,
      );
    });
  });
}
