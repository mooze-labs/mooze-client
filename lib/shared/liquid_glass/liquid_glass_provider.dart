import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';

/// Liquid Glass is an iPhone-only visual treatment. Other platforms keep the
/// classic opaque chrome.
final liquidGlassSupportedProvider = Provider<bool>((ref) => Platform.isIOS);

/// User preference for Liquid Glass. Stored in SharedPreferences and read
/// synchronously, so the first frame already uses the correct chrome.
class LiquidGlassEnabledNotifier extends Notifier<bool> {
  static const _key = 'liquidGlassEnabled';

  @override
  bool build() {
    // Default ON: iPhone users get the native-looking chrome out of the box.
    return ref.read(sharedPreferencesProvider).getBool(_key) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    await ref.read(sharedPreferencesProvider).setBool(_key, enabled);
    state = enabled;
  }
}

final liquidGlassEnabledProvider =
    NotifierProvider<LiquidGlassEnabledNotifier, bool>(
      LiquidGlassEnabledNotifier.new,
    );

/// True when the UI must render Liquid Glass: the platform supports it and
/// the user has not switched it off.
final liquidGlassActiveProvider = Provider<bool>((ref) {
  return ref.watch(liquidGlassSupportedProvider) &&
      ref.watch(liquidGlassEnabledProvider);
});
