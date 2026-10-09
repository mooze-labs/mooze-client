import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/shared/analytics/events.dart';
import 'package:mooze_mobile/shared/analytics/posthog_sink.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('posthog_flutter');
  final calls = <MethodCall>[];
  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  test(
    'the real Dart SDK filters payloads and disables automatic collection',
    () async {
      var allowed = true;
      final sink = await PosthogSink.start(
        token: 'phc_test',
        host: 'https://us.i.posthog.com',
        environment: 'test',
        version: '1.0',
        allowed: () => allowed,
      );
      final setup =
          calls.firstWhere((call) => call.method == 'setup').arguments as Map;
      expect(setup['captureApplicationLifecycleEvents'], false);
      expect(setup['sessionReplay'], false);
      expect(setup['surveys'], false);
      expect(setup['preloadFeatureFlags'], false);
      expect(setup['capturePushNotificationSubscriptions'], false);
      expect(setup['capturePushNotificationOpened'], false);
      await Posthog().capture(
        eventName: 'send_started',
        properties: {
          'chain': 'bitcoin',
          'address': 'secret',
          r'$screen_name': 'secret',
        },
      );
      final capture =
          calls.singleWhere((call) => call.method == 'capture').arguments
              as Map;
      expect(capture['properties'], {
        'chain': 'bitcoin',
        'platform': 'mobile',
        'app_version': '1.0',
        'environment': 'test',
        'network': 'mainnet',
        'event_schema_version': 1,
        r'$geoip_disable': true,
      });
      await Posthog().capture(
        eventName: r'$identify',
        properties: {'email': 'secret'},
      );
      expect(calls.where((c) => c.method == 'capture'), hasLength(1));
      allowed = false;
      await sink.stop();
      await sink.capture(AnalyticsEvent.screen('wallet'));
      expect(calls.where((c) => c.method == 'capture'), hasLength(1));
      expect(calls.where((c) => c.method == 'disable'), hasLength(1));
      expect(calls.where((c) => c.method == 'close'), hasLength(1));
    },
  );

  test('cancellation before setup never touches the native SDK', () async {
    final sink = await PosthogSink.start(
      token: 'phc_test',
      host: 'https://us.i.posthog.com',
      environment: 'test',
      version: '1.0',
      allowed: () => false,
    );
    await sink.stop();
    expect(calls, isEmpty);
  });
}
