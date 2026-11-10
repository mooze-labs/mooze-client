import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/setup/presentation/screens/first_access/first_access.dart';
import 'package:mooze_mobile/shared/analytics/analytics.dart';
import 'package:mooze_mobile/shared/analytics/providers.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'setup_test_app.dart';

class _MemoryConsent implements ConsentStore {
  bool value = false;

  @override
  bool read() => value;

  @override
  Future<void> write(bool enabled) async => value = enabled;
}

void main() {
  late OpenedRoutes opened;
  late SharedPreferences prefs;

  setUp(() async {
    opened = OpenedRoutes();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> open(
    WidgetTester tester, {
    bool analyticsConfigured = false,
    double textScale = 1,
  }) async {
    usePhoneSize(tester);
    final router = GoRouter(
      initialLocation: '/setup/first-access',
      routes: [
        GoRoute(
          path: '/setup/first-access',
          builder: (_, _) => const FirstAccessScreen(),
        ),
        opened.stub('/setup/create-wallet/configure-seeds'),
        opened.stub('/setup/import-wallet'),
      ],
    );
    await tester.pumpWidget(
      setupTestApp(
        router: router,
        textScale: textScale,
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          if (analyticsConfigured)
            analyticsProvider.overrideWith(
              (ref) => AnalyticsController(
                configured: true,
                store: _MemoryConsent(),
                load: (_) async => throw UnimplementedError(),
              ),
            ),
        ],
      ),
    );
    await settle(tester);
  }

  bool createEnabled(WidgetTester tester) =>
      tester.widget<PrimaryButton>(find.byType(PrimaryButton)).isEnabled;

  bool importEnabled(WidgetTester tester) =>
      tester
          .widget<TextButton>(
            find.ancestor(
              of: find.text('Importar carteira'),
              matching: find.byType(TextButton),
            ),
          )
          .onPressed !=
      null;

  testWidgets('both ways in wait for the terms', (tester) async {
    await open(tester);

    expect(createEnabled(tester), isFalse);
    expect(importEnabled(tester), isFalse);

    await tester.tap(find.byType(Checkbox));
    await settle(tester);

    expect(createEnabled(tester), isTrue);
    expect(importEnabled(tester), isTrue);
  });

  testWidgets('create opens the phrase length step', (tester) async {
    await open(tester);
    await tester.tap(find.byType(Checkbox));
    await settle(tester);

    await tester.tap(find.text('Criar Carteira'));
    await settle(tester);

    expect(opened.last, '/setup/create-wallet/configure-seeds');
  });

  testWidgets('import opens the import screen', (tester) async {
    await open(tester);
    await tester.tap(find.byType(Checkbox));
    await settle(tester);

    await tester.tap(find.text('Importar carteira'));
    await settle(tester);

    expect(opened.last, '/setup/import-wallet');
  });

  testWidgets('sits on the screen backdrop, with the terms and analytics', (
    tester,
  ) async {
    await open(tester, analyticsConfigured: true);

    expect(find.byType(AppBackdrop), findsWidgets);
    expect(find.byType(Checkbox), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('fits a phone at 200% text', (tester) async {
    await open(tester, analyticsConfigured: true, textScale: 2);

    expect(tester.takeException(), isNull);
    expect(find.text('Criar Carteira'), findsOneWidget);
  });
}
