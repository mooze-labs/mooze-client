import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/features/settings/presentation/providers/locale_provider.dart';

final localeStringProvider = Provider<String>((ref) {
  final overridden = ref.watch(localeProvider);
  if (overridden != null) {
    return _withRegion(overridden.languageCode);
  }
  final device = PlatformDispatcher.instance.locale.languageCode;
  return _withRegion(device);
});

String _withRegion(String languageCode) {
  switch (languageCode) {
    case 'pt':
      return 'pt_BR';
    case 'es':
      return 'es_ES';
    case 'en':
    default:
      return 'en_US';
  }
}
