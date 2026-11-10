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

  testWidgets('the API down banner still opens its dialog', (tester) async {
    await pump(tester, homeTop, apiDown: true);

    expect(find.byType(StatusBanner), findsOneWidget);
    await tester.tap(find.byType(StatusBanner));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
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
