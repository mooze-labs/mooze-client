import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/home/header.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/authentication/providers/ensure_auth_session_provider.dart';
import 'package:mooze_mobile/shared/connectivity/providers/connectivity_provider.dart';
import 'package:mooze_mobile/shared/connectivity/widgets.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/status_banner.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

import '../widgets/motion/motion_test_helpers.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    bool offline = true,
    bool syncError = false,
    bool apiDown = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isUsingCacheProvider.overrideWithValue(offline),
          syncErrorProvider.overrideWith((ref) => syncError),
          apiDownProvider.overrideWith((ref) => apiDown),
          ensureAuthSessionProvider.overrideWith((ref) async => true),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('pt'),
          builder: (context, child) =>
              Theme(data: AppTheme.lightTheme(context), child: child!),
          home: Scaffold(body: child),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The top of the home without the island: the header, then the status
  /// banners.
  const homeTop = Column(children: [LogoHeader(), StatusIndicators()]);

  testWidgets('the header and the banners carry no offline pill: the '
      'status island shows it', (tester) async {
    await pump(tester, homeTop, syncError: true);

    expect(find.byType(OfflineIndicator), findsNothing);
    expect(find.text('Offline'), findsNothing);
  });

  testWidgets('a failed sync is not a banner: the status island shows it', (
    tester,
  ) async {
    await pump(tester, homeTop, syncError: true);

    expect(find.byType(StatusBanner), findsNothing);
    expect(find.text('Erro de Sincronização'), findsNothing);
  });

  testWidgets('no status, no banner', (tester) async {
    await pump(tester, homeTop, offline: false);

    expect(find.byType(StatusBanner), findsNothing);
    expect(find.text('Offline'), findsNothing);
  });

  testWidgets('the API down banner opens a floating glass sheet with what '
      'stops working', (tester) async {
    final t = lookupAppLocalizations(const Locale('pt'));
    await pump(tester, homeTop, apiDown: true);

    expect(find.byType(StatusBanner), findsOneWidget);
    await tester.tap(find.byType(StatusBanner));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    final sheet = find.byType(ApiDownSheet);
    expect(sheet, findsOneWidget);
    Finder inSheet(Finder f) => find.descendant(of: sheet, matching: f);
    expect(inSheet(find.byType(GlassSheet)), findsOneWidget);
    expect(inSheet(find.text(t.api_down_dialog_title)), findsOneWidget);
    expect(inSheet(find.text(t.api_down_maintenance_title)), findsOneWidget);
    expect(inSheet(find.text(t.api_down_warning_list)), findsOneWidget);

    await tester.tap(inSheet(find.text(t.common_close)));
    await tester.pumpAndSettle();
    expect(find.byType(ApiDownSheet), findsNothing);
    expect(find.byType(StatusBanner), findsOneWidget);
  });

  testWidgets('retry closes the API down sheet and runs onRetry', (
    tester,
  ) async {
    final t = lookupAppLocalizations(const Locale('pt'));
    var retries = 0;
    await pump(
      tester,
      Column(
        children: [
          const LogoHeader(),
          StatusIndicators(onRetrySync: () => retries++),
        ],
      ),
      apiDown: true,
    );

    await tester.tap(find.byType(StatusBanner));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.common_retry));
    await tester.pumpAndSettle();

    expect(retries, 1);
    expect(find.byType(ApiDownSheet), findsNothing);
  });

  testWidgets('the API down icon of a bar opens the same sheet', (
    tester,
  ) async {
    final t = lookupAppLocalizations(const Locale('pt'));
    await pump(
      tester,
      const Center(child: ApiDownIndicatorIcon()),
      apiDown: true,
    );

    await tester.tap(find.byTooltip(t.api_down_dialog_title));
    await tester.pumpAndSettle();

    expect(find.byType(ApiDownSheet), findsOneWidget);
  });

  testWidgets('under reduced motion the API down banner shows without the '
      'size animation', (tester) async {
    reduceMotion(tester);
    final container = ProviderContainer(
      overrides: [
        isUsingCacheProvider.overrideWithValue(false),
        syncErrorProvider.overrideWith((ref) => false),
        ensureAuthSessionProvider.overrideWith((ref) async => true),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('pt'),
          builder: (context, child) =>
              Theme(data: AppTheme.lightTheme(context), child: child!),
          home: const Scaffold(body: homeTop),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(StatusBanner), findsNothing);

    // The API goes down while the home shows.
    container.read(apiDownProvider.notifier).state = true;
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(StatusBanner), findsOneWidget);
    expect(find.byType(AnimatedSize), findsNothing);
  });

  testWidgets('the Offline pill is glass and a tap on it runs onTap', (
    tester,
  ) async {
    var taps = 0;
    await pump(tester, Center(child: OfflineIndicator(onTap: () => taps++)));

    expect(
      find.descendant(
        of: find.byType(OfflineIndicator),
        matching: find.byType(LiquidGlass),
      ),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byType(OfflineIndicator)).height,
      greaterThanOrEqualTo(48),
    );

    await tester.tap(find.text('Offline'));
    expect(taps, 1);
  });
}
