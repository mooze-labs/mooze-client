import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/settings/presentation/providers/advanced_settings_provider.dart';
import 'package:mooze_mobile/features/settings/presentation/screens/fee_settings_screen.dart';
import 'package:mooze_mobile/features/settings/routes.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/send_funds/lbtc_fee_warning_badge.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final t = lookupAppLocalizations(const Locale('pt'));

  /// A send screen with the info button, an address field, and a line that
  /// says whether the custom fee is on. The settings screens open over it.
  Future<void> pump(WidgetTester tester, {required bool customFee}) async {
    SharedPreferences.setMockInitialValues({
      SendCustomFeeEnabledNotifier.key: customFee,
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp.router(
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              Theme(data: AppTheme.darkTheme(context), child: child!),
          routerConfig: GoRouter(
            initialLocation: '/send-asset',
            routes: [
              GoRoute(
                path: '/send-asset',
                builder: (context, state) => Scaffold(
                  appBar: AppBar(actions: const [LbtcFeeInfoButton()]),
                  body: Column(
                    children: [
                      const TextField(),
                      Consumer(
                        builder: (context, ref, _) => Text(
                          ref.watch(sendCustomFeeEnabledProvider)
                              ? 'custom on'
                              : 'custom off',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // The routes of the app, so the button must name the real one.
              ...settingsRoutes,
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openInfo(WidgetTester tester) async {
    await tester.tap(find.byTooltip(t.wallet_send_lbtc_info_title));
    await tester.pumpAndSettle();
  }

  testWidgets('with the custom fee off, the sheet tells about it and offers '
      'to turn it on', (tester) async {
    await pump(tester, customFee: false);
    await openInfo(tester);

    expect(find.text(t.wallet_send_custom_fee_info_title), findsOneWidget);
    expect(find.text(t.wallet_send_custom_fee_info_off_desc), findsOneWidget);
    expect(find.text(t.wallet_send_custom_fee_turn_on), findsOneWidget);
    // The swap stays the main action.
    expect(find.text(t.wallet_send_lbtc_go_swap), findsOneWidget);
  });

  testWidgets('the fee settings open over the send screen, and their back '
      'button returns to the send with the form kept', (tester) async {
    await pump(tester, customFee: false);
    await tester.enterText(find.byType(TextField), 'bc1qaddress');
    await openInfo(tester);

    await tester.tap(find.text(t.wallet_send_custom_fee_turn_on));
    await tester.pumpAndSettle();
    expect(find.byType(FeeSettingsScreen), findsOneWidget);
    await tester.tap(
      find.widgetWithText(SwitchListTile, t.custom_fee_toggle_title),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(FeeSettingsScreen), findsNothing);
    expect(find.text('bc1qaddress'), findsOneWidget);
    expect(find.text('custom on'), findsOneWidget);
    // The sheet closed before the settings opened.
    expect(find.text(t.wallet_send_custom_fee_info_title), findsNothing);
  });

  testWidgets('with the custom fee on, the sheet tells where to find it, '
      'and its button opens the settings to configure it', (tester) async {
    await pump(tester, customFee: true);
    await openInfo(tester);

    expect(find.text(t.wallet_send_custom_fee_info_on_desc), findsOneWidget);
    expect(find.text(t.wallet_send_custom_fee_turn_on), findsNothing);

    await tester.tap(find.text(t.wallet_send_custom_fee_configure));
    await tester.pumpAndSettle();
    expect(find.byType(FeeSettingsScreen), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('custom on'), findsOneWidget);
  });

  testWidgets('the sheet no longer offers Lightning', (tester) async {
    await pump(tester, customFee: false);
    await openInfo(tester);

    expect(find.textContaining('Lightning'), findsNothing);
    expect(find.text(t.wallet_send_lbtc_info_step3_title), findsOneWidget);
  });
}
