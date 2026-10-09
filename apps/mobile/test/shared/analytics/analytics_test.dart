import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/shared/analytics/analytics.dart';
import 'package:mooze_mobile/shared/analytics/events.dart';

class MemoryConsent implements ConsentStore {
  bool enabled = false;
  bool fail = false;
  @override
  bool read() => enabled;
  @override
  Future<void> write(bool value) async {
    if (fail) throw StateError('storage unavailable');
    enabled = value;
  }
}

class RecordingSink implements AnalyticsSink {
  final events = <AnalyticsEvent>[];
  bool stopped = false;
  @override
  Future<void> capture(AnalyticsEvent event) async => events.add(event);
  @override
  Future<void> stop() async {
    stopped = true;
  }
}

void main() {
  test('PIX and swap events exclude financial data and provider errors', () {
    for (final name in [
      'pix_request_started',
      'pix_request_created',
      'pix_request_failed',
      'pix_code_copied',
    ]) {
      expect(
        sanitizeEvent(name, {
          'pix_key': 'secret',
          'tax_id': 'secret',
          'amount': 123,
        })?.properties,
        <String, Object>{},
      );
    }
    expect(
      sanitizeEvent('pix_deposit_status_changed', {
        'status': 'completed',
        'deposit_id': 'secret',
      })?.properties,
      {'status': 'completed'},
    );
    expect(
      sanitizeEvent('pix_deposit_status_changed', {
        'status': 'raw provider error',
      }),
      isNull,
    );
    for (final name in [
      'swap_review_opened',
      'swap_started',
      'swap_submission_succeeded',
      'swap_failed',
    ]) {
      expect(
        sanitizeEvent(name, {
          'swap_type': 'peg_in',
          'txid': 'secret',
          'amount': 123,
          'error': 'secret',
        })?.properties,
        {'swap_type': 'peg_in'},
      );
      expect(sanitizeEvent(name, {'swap_type': 'arbitrary-asset-id'}), isNull);
    }
  });
  test(
    'no SDK initialization or buffering before consent; revocation stops delivery',
    () async {
      final store = MemoryConsent();
      final sink = RecordingSink();
      var loads = 0;
      final analytics = AnalyticsController(
        configured: true,
        store: store,
        load: (_) async {
          loads++;
          return sink;
        },
      );
      await analytics.start();
      analytics.track(AnalyticsEvent.screen('wallet'));
      expect(loads, 0);
      await analytics.setEnabled(true);
      expect(sink.events, isEmpty);
      analytics.track(AnalyticsEvent.screen('settings'));
      expect(sink.events.single.properties, {'screen_name': 'settings'});
      await analytics.setEnabled(false);
      analytics.track(AnalyticsEvent.screen('wallet'));
      expect(sink.events, hasLength(1));
      expect(sink.stopped, isTrue);
    },
  );

  test('revocation wins against an in-progress SDK load', () async {
    final pending = Completer<AnalyticsSink>();
    final sink = RecordingSink();
    final analytics = AnalyticsController(
      configured: true,
      store: MemoryConsent(),
      load: (_) => pending.future,
    );
    final enable = analytics.setEnabled(true);
    await Future<void>.delayed(Duration.zero);
    final disable = analytics.setEnabled(false);
    pending.complete(sink);
    await Future.wait([enable, disable]);
    analytics.track(AnalyticsEvent.screen('wallet'));
    expect(sink.events, isEmpty);
    expect(sink.stopped, isTrue);
    expect(analytics.enabled, isFalse);
  });

  test('storage failure never enables collection', () async {
    final store = MemoryConsent()..fail = true;
    var loads = 0;
    final analytics = AnalyticsController(
      configured: true,
      store: store,
      load: (_) async {
        loads++;
        return RecordingSink();
      },
    );
    expect(await analytics.setEnabled(true), isFalse);
    expect(loads, 0);
    expect(analytics.enabled, isFalse);
  });

  test('event allowlist drops arbitrary properties and values', () {
    expect(sanitizeEvent(r'$identify', {'email': 'secret'}), isNull);
    expect(
      sanitizeEvent('send_started', {
        'chain': 'bitcoin',
        'address': 'secret',
      })?.properties,
      {'chain': 'bitcoin'},
    );
    expect(
      sanitizeEvent('send_failed', {
        'chain': 'liquid',
        'error_code': 'secret raw error',
      }),
      isNull,
    );
    expect(screenForPath('/send-asset?address=secret'), 'send');
    expect(screenForPath('/settings/view-mnemonic'), isNull);
    expect(screenForPath('/unknown/secret'), isNull);
  });
}
