import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:mooze_mobile/features/settings/presentation/providers/theme_mode_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final entry in <String?, ThemeMode>{null: ThemeMode.system, 'invalid': ThemeMode.system, 'light': ThemeMode.light, 'dark': ThemeMode.dark, 'system': ThemeMode.system}.entries) {
    test('restores ${entry.key} and persists each mode', () async {
      SharedPreferences.setMockInitialValues({if (entry.key != null) 'appThemeMode': entry.key!});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
      addTearDown(container.dispose);
      expect(container.read(themeModeProvider), entry.value);
      for (final mode in ThemeMode.values) {
        await container.read(themeModeProvider.notifier).setThemeMode(mode);
        expect(container.read(themeModeProvider), mode);
        expect(prefs.getString('appThemeMode'), mode.name);
      }
    });
  }
}
