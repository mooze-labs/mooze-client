import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mooze_mobile/app/session/auth_prompt_controller.dart';
import 'package:mooze_mobile/app/session/privacy_shield_controller.dart';
import 'package:mooze_mobile/app/session/privacy_shield_state.dart';
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

  group('PrivacyShieldController', () {
    test('starts hidden', () async {
      final container = await _container({});
      expect(
        container.read(privacyShieldControllerProvider),
        PrivacyShieldState.hidden,
      );
    });

    test('privacy shield enabled → leaving foreground shows the shield',
        () async {
      // Defaults: both enabled.
      final container = await _container({});
      container
          .read(privacyShieldControllerProvider.notifier)
          .onLeavingForeground();
      expect(
        container.read(privacyShieldControllerProvider),
        PrivacyShieldState.visible,
      );
    });

    test('both features disabled → no shield on leaving foreground', () async {
      final container = await _container({
        'privacyShieldEnabled': false,
        'sessionLockEnabled': false,
      });
      container
          .read(privacyShieldControllerProvider.notifier)
          .onLeavingForeground();
      expect(
        container.read(privacyShieldControllerProvider),
        PrivacyShieldState.hidden,
      );
    });

    test(
        'shield disabled but session lock enabled still covers (zero-flash '
        'coupling)', () async {
      final container = await _container({
        'privacyShieldEnabled': false,
        'sessionLockEnabled': true,
      });
      container
          .read(privacyShieldControllerProvider.notifier)
          .onLeavingForeground();
      expect(
        container.read(privacyShieldControllerProvider),
        PrivacyShieldState.visible,
      );
    });

    test('does NOT raise while a native auth prompt is active', () async {
      // Simulates the biometric prompt firing `inactive`: the shield must stay
      // hidden so the auth UI (with its "Use PIN" fallback) remains visible.
      final container = await _container({});
      container.read(authPromptActiveProvider.notifier).begin();

      container
          .read(privacyShieldControllerProvider.notifier)
          .onLeavingForeground();

      expect(
        container.read(privacyShieldControllerProvider),
        PrivacyShieldState.hidden,
      );
    });

    test('resume always drops the shield', () async {
      final container = await _container({});
      final controller =
          container.read(privacyShieldControllerProvider.notifier);

      controller.onLeavingForeground();
      expect(
        container.read(privacyShieldControllerProvider),
        PrivacyShieldState.visible,
      );

      controller.onResumed();
      expect(
        container.read(privacyShieldControllerProvider),
        PrivacyShieldState.hidden,
      );
    });
  });
}
