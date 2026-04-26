import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';

const supportedLocales = <Locale>[
  Locale('pt'),
  Locale('en'),
  Locale('es'),
];

class LocaleNotifier extends Notifier<Locale?> {
  static const _key = 'appLocale';

  @override
  Locale? build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final stored = prefs.getString(_key);
    if (stored == null) return null;
    return _decode(stored);
  }

  Future<void> setLocale(Locale? locale) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (locale == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, locale.languageCode);
    }
    state = locale;
  }

  Locale? _decode(String value) {
    final match = supportedLocales
        .where((l) => l.languageCode == value)
        .toList();
    return match.isEmpty ? null : match.first;
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);
