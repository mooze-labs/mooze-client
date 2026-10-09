import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/shared/analytics/events.dart';
import 'package:mooze_mobile/shared/analytics/product_flows.dart';

void main() {
  test(
    'operations preserve the wallet result and error and emit one outcome',
    () async {
      final events = <String>[];
      const started = AnalyticsEvent('pix_request_started', {});
      const succeeded = AnalyticsEvent('pix_request_created', {});
      const failed = AnalyticsEvent('pix_request_failed', {});
      final value = Object();
      expect(
        await trackOperation(
          track: (e) => events.add(e.name),
          started: started,
          failed: failed,
          outcome: (_) => succeeded,
          run: () async => value,
        ),
        same(value),
      );
      final error = StateError('private error');
      await expectLater(
        trackOperation<Object>(
          track: (e) => events.add(e.name),
          started: started,
          failed: failed,
          outcome: (_) => succeeded,
          run: () async => throw error,
        ),
        throwsA(same(error)),
      );
      expect(events, [
        'pix_request_started',
        'pix_request_created',
        'pix_request_started',
        'pix_request_failed',
      ]);
    },
  );
  test(
    'PIX status deduplicates stages and never replays initial history or pre-consent activity',
    () {
      var enabled = false;
      final events = <AnalyticsEvent>[];
      final tracker = PixStatusTracker(
        allowed: () => enabled,
        track: events.add,
      );
      tracker.observe('private-id', 'pending');
      enabled = true;
      tracker.observe('private-id', 'completed');
      tracker.observe('new-id', 'pending');
      tracker.observe('new-id', 'underReview');
      tracker.observe('new-id', 'paid');
      tracker.observe('new-id', 'finished');
      tracker.observe('new-id', 'completed');
      expect(events.map((e) => e.properties).toList(), [
        {'status': 'processing'},
        {'status': 'completed'},
      ]);
      tracker.clear();
      tracker.observe('new-id', 'refunded');
      expect(events, hasLength(2));
    },
  );
}
