import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';

/// Advanced preferences, persisted via SharedPreferences and read
/// synchronously in `build()`, like the security preferences.

/// "Economy fee" — whether the confirm sheet of a BTC to L-BTC swap offers
/// the economic Bitcoin fee speed. With a low fee the swap can wait hours
/// or days for the Bitcoin transaction to confirm.
class PegLowFeeEnabledNotifier extends Notifier<bool> {
  static const key = 'pegLowFeeEnabled';

  @override
  bool build() {
    // Default OFF: the normal and the fast speed confirm in a predictable
    // time.
    return ref.read(sharedPreferencesProvider).getBool(key) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    await ref.read(sharedPreferencesProvider).setBool(key, enabled);
    state = enabled;
  }
}

final pegLowFeeEnabledProvider =
    NotifierProvider<PegLowFeeEnabledNotifier, bool>(
      PegLowFeeEnabledNotifier.new,
    );

/// "Custom fee" — whether the speed choice of a Bitcoin on-chain send offers
/// a custom fee rate. A rate below the economic speed can leave the
/// transaction waiting for days, and a high one pays more than needed.
class SendCustomFeeEnabledNotifier extends Notifier<bool> {
  static const key = 'sendCustomFeeEnabled';

  @override
  bool build() {
    // Default OFF: the preset speeds suit most sends.
    return ref.read(sharedPreferencesProvider).getBool(key) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    await ref.read(sharedPreferencesProvider).setBool(key, enabled);
    state = enabled;
  }
}

final sendCustomFeeEnabledProvider =
    NotifierProvider<SendCustomFeeEnabledNotifier, bool>(
      SendCustomFeeEnabledNotifier.new,
    );
