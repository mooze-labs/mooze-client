import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_withdrawal_record.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_send_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/pix_hub_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_formatters.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_primary_action_cards.dart';
import 'package:mooze_mobile/features/pix/shared/data/services/pix_onboarding_service.dart';
import 'package:mooze_mobile/features/pix/shared/di/providers/pix_onboarding_service_provider.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/app_theme.dart';

/// Height of the bar the shell places over the bottom of the hub.
const double _navBarHeight = 110;

/// Skips the first-access dialogs, which have their own tests.
class _SeenOnboarding implements PixOnboardingService {
  @override
  Future<bool> hasSeenFirstTimeDialog() async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Renders the hub as the shell does: the body extends under the bar.
Widget host({List<PixWithdrawalRecord> pending = const []}) {
  return ProviderScope(
    overrides: [
      pixOnboardingServiceProvider.overrideWithValue(_SeenOnboarding()),
      pixPendingWithdrawalsProvider.overrideWith((ref) => pending),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('pt'),
      home: Builder(
        builder: (context) => Theme(
          data: AppTheme.darkTheme(context),
          child: const Scaffold(
            extendBody: true,
            body: PixHubScreen(),
            bottomNavigationBar: SizedBox(height: _navBarHeight),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('the last row ends above the navigation bar', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();

    final lastRow = tester.getRect(find.text('Meu nível'));
    expect(lastRow.bottom, lessThan(667 - _navBarHeight));
  });

  testWidgets('the content keeps a readable width on tablets', (tester) async {
    tester.view.physicalSize = const Size(1024, 1366);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await tester.pump();

    final card = tester.getRect(find.byType(PixHighlightActionCard));
    expect(card.width, 560);
    expect(card.center.dx, 512);
  });

  testWidgets('lists the Pix sends that wait for a final status', (
    tester,
  ) async {
    final record = PixWithdrawalRecord(
      id: 'w-1',
      createdAt: DateTime.utc(2026, 10, 24, 12),
      payoutAmountInCents: 4590,
      depositAmountInCents: 4689,
      depositAmountSats: 4689000000,
      depositAddress: 'lq1qqdeposit',
      expiresAt: DateTime.utc(2026, 10, 24, 12, 30),
      maskedKey: 'a***@exemplo.com.br',
      fundingStatus: PixFundingStatus.uncertain,
    );

    await tester.pumpWidget(host(pending: [record]));
    await tester.pump();

    expect(find.text('Pix em andamento'), findsOneWidget);
    expect(
      find.text('${formatBrlCents(4590)} para a***@exemplo.com.br'),
      findsOneWidget,
    );
  });

  testWidgets('shows no section without pending Pix sends', (tester) async {
    await tester.pumpWidget(host());
    await tester.pump();

    expect(find.text('Pix em andamento'), findsNothing);
  });
}
