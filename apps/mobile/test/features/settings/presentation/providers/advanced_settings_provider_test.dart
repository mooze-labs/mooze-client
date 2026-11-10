import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mooze_mobile/features/settings/presentation/providers/advanced_settings_provider.dart';
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

  group('peg low fee', () {
    test('is off by default', () async {
      final container = await _container({});
      expect(container.read(pegLowFeeEnabledProvider), isFalse);
    });

    test('reads the persisted value', () async {
      final container = await _container({PegLowFeeEnabledNotifier.key: true});
      expect(container.read(pegLowFeeEnabledProvider), isTrue);
    });

    test('setEnabled persists and updates state', () async {
      final container = await _container({});
      await container.read(pegLowFeeEnabledProvider.notifier).setEnabled(true);

      expect(container.read(pegLowFeeEnabledProvider), isTrue);
      final sp = await SharedPreferences.getInstance();
      expect(sp.getBool(PegLowFeeEnabledNotifier.key), isTrue);
    });
  });

  group('send custom fee', () {
    test('is off by default', () async {
      final container = await _container({});
      expect(container.read(sendCustomFeeEnabledProvider), isFalse);
    });

    test('reads the persisted value', () async {
      final container = await _container({
        SendCustomFeeEnabledNotifier.key: true,
      });
      expect(container.read(sendCustomFeeEnabledProvider), isTrue);
    });

    test('setEnabled persists and updates state', () async {
      final container = await _container({});
      await container
          .read(sendCustomFeeEnabledProvider.notifier)
          .setEnabled(true);

      expect(container.read(sendCustomFeeEnabledProvider), isTrue);
      final sp = await SharedPreferences.getInstance();
      expect(sp.getBool(SendCustomFeeEnabledNotifier.key), isTrue);
    });
  });
}
