import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../user/providers/user_service_provider.dart'
    show sharedPreferencesProvider;
import 'analytics.dart';
import 'posthog_sink.dart';
import 'product_flows.dart';

class PreferencesConsentStore implements ConsentStore {
  PreferencesConsentStore(this.preferences);
  final SharedPreferences preferences;
  static const key = 'mooze.analytics.consent.v1';
  @override
  bool read() => preferences.getBool(key) ?? false;
  @override
  Future<void> write(bool enabled) async {
    if (!await preferences.setBool(key, enabled)) {
      throw StateError('Consent was not saved');
    }
  }
}

final analyticsProvider = ChangeNotifierProvider<AnalyticsController>((ref) {
  const token = String.fromEnvironment('POSTHOG_TOKEN');
  const host = String.fromEnvironment('POSTHOG_HOST');
  const environment = String.fromEnvironment(
    'ANALYTICS_ENVIRONMENT',
    defaultValue: 'development',
  );
  final supported =
      !kIsWeb &&
      {
        TargetPlatform.android,
        TargetPlatform.iOS,
      }.contains(defaultTargetPlatform);
  return AnalyticsController(
    configured:
        supported &&
        token.startsWith('phc_') &&
        RegExp(r'^https://[^/?#]+/?$').hasMatch(host),
    store: PreferencesConsentStore(ref.watch(sharedPreferencesProvider)),
    load: (allowed) async {
      final info = await PackageInfo.fromPlatform();
      return PosthogSink.start(
        token: token,
        host: host,
        environment: environment,
        version: info.version,
        allowed: allowed,
      );
    },
  );
});

// Setup flow context only; never populated from wallet data.
final analyticsSetupMethodProvider = StateProvider<String?>((ref) => null);

final pixAnalyticsProvider = Provider<PixStatusTracker>((ref) {
  final analytics = ref.read(analyticsProvider);
  final tracker = PixStatusTracker(
    allowed: () => analytics.enabled && !analytics.busy,
    track: analytics.track,
  );
  ref.listen(analyticsProvider, (_, next) {
    if (!next.enabled) tracker.clear();
  });
  return tracker;
});
