import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/analytics/analytics.dart';
import 'package:mooze_mobile/shared/analytics/analytics_setting.dart';
import 'package:mooze_mobile/shared/analytics/providers.dart';
import 'analytics_test.dart' show MemoryConsent, RecordingSink;

void main() {
  testWidgets('compact opt-in explains collection and cancel leaves it off', (
    tester,
  ) async {
    final store = MemoryConsent();
    final analytics = AnalyticsController(
      configured: true,
      store: store,
      load: (_) async => RecordingSink(),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [analyticsProvider.overrideWith((ref) => analytics)],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: AnalyticsSetting(compact: true)),
        ),
      ),
    );
    expect(tester.widget<Switch>(find.byType(Switch)).value, false);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.textContaining('PostHog'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(store.enabled, false);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(store.enabled, true);
    expect(tester.widget<Switch>(find.byType(Switch)).value, true);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(store.enabled, false);
  });
}
