import 'package:posthog_flutter/posthog_flutter.dart';
import 'analytics.dart';
import 'events.dart';

class PosthogSink implements AnalyticsSink {
  PosthogSink(this._sdk, this._allowed);
  final Posthog _sdk;
  final bool Function() _allowed;

  static Future<AnalyticsSink> start({
    required String token,
    required String host,
    required String environment,
    required String version,
    required bool Function() allowed,
  }) async {
    if (!allowed()) return const _InactiveSink();
    final sdk = Posthog();
    final config = PostHogConfig(token)
      ..host = host
      ..optOut = true
      ..personProfiles = PostHogPersonProfiles.never
      ..sessionReplay = false
      ..surveys = false
      ..captureApplicationLifecycleEvents = false
      ..preloadFeatureFlags = false
      ..sendFeatureFlagEvent = false
      ..capturePushNotificationSubscriptions = false
      ..capturePushNotificationOpened = false
      ..maxQueueSize = 100
      ..debug = false;
    config.rageClickConfig.enabled = false;
    config.errorTrackingConfig
      ..captureFlutterErrors = false
      ..capturePlatformDispatcherErrors = false
      ..captureIsolateErrors = false
      ..captureNativeExceptions = false
      ..captureNativeCrashes = false;
    config.errorTrackingConfig.exceptionSteps.enabled = false;
    config.logsConfig.beforeSend = [(_) => null];
    config.beforeSend = [
      (event) {
        if (!allowed()) return null;
        final safe = sanitizeEvent(event.event, event.properties ?? {});
        if (safe == null) return null;
        return PostHogEvent(
          event: safe.name,
          properties: {
            ...safe.properties,
            'platform': 'mobile',
            'app_version': version,
            'environment': environment,
            'network': 'mainnet',
            'event_schema_version': 1,
            r'$geoip_disable': true,
          },
        );
      },
    ];
    await sdk.setup(config);
    if (allowed()) await sdk.optIn();
    return PosthogSink(sdk, allowed);
  }

  @override
  Future<void> capture(AnalyticsEvent event) async {
    if (_allowed()) {
      await _sdk.capture(eventName: event.name, properties: event.properties);
    }
  }

  @override
  Future<void> stop() async {
    await _sdk.optOut();
    await _sdk.close();
  }
}

class _InactiveSink implements AnalyticsSink {
  const _InactiveSink();
  @override
  Future<void> capture(AnalyticsEvent event) async {}
  @override
  Future<void> stop() async {}
}
