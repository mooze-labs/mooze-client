import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_qr_panel.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/asset_quote_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/fee_rate_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/screens/payment/pix_payment_screen.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/screens/payment/widgets/timer_countdown_widget.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// When the charge was created.
final _created = DateTime(2026, 11, 12, 10);

/// A Pix charge is valid for 20 minutes.
final _expiry = _created.add(const Duration(minutes: 20));

final _deposit = PixDeposit(
  depositId: 'deposit-1',
  pixKey: 'sample-pix-code-for-the-expiry-test',
  asset: Asset.depix,
  amountInCents: 5000,
  network: 'liquid',
  status: DepositStatus.pending,
  createdAt: _created,
);

void main() {
  final t = lookupAppLocalizations(const Locale('pt'));

  /// The clock of the countdown.
  late DateTime now;

  setUp(() => TimerCountdown.clock = () => now);
  tearDown(() => TimerCountdown.clock = DateTime.now);

  /// Opens the charge over a home screen, as from the Pix hub.
  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.push('/payment'),
              child: const Text('home'),
            ),
          ),
        ),
        GoRoute(
          path: '/payment',
          builder: (_, _) => ValidPixPaymentScreen(deposit: _deposit),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          assetQuoteProvider.overrideWith((ref, asset) async => right(some(5))),
          feeRateProvider.overrideWith((ref, amount) async => 0),
          discountedFeesDepositProvider.overrideWith(
            (ref, amount) async => amount,
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              Theme(data: AppTheme.darkTheme(context), child: child!),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('home'));
    await frames(tester);
  }

  Finder notice() => find.descendant(
    of: find.byType(GlassSheet),
    matching: find.text(t.human_verif_time_expired_title),
  );

  testWidgets('while the time runs, the charge shows its QR Code', (
    tester,
  ) async {
    now = _expiry.subtract(const Duration(minutes: 5));
    await open(tester);

    expect(find.byType(PixQrPanel), findsOneWidget);
    expect(notice(), findsNothing);
  });

  // The Pix no longer pays once the time ends. A notice says so in a
  // floating sheet, as the other notices of the app.
  testWidgets('when the time ends, a floating sheet says so', (tester) async {
    now = _expiry.subtract(const Duration(seconds: 2));
    await open(tester);
    expect(notice(), findsNothing);

    now = _expiry;
    await tester.pump(const Duration(seconds: 1));
    await frames(tester);

    expect(notice(), findsOneWidget);
    expect(find.text(t.pix_payment_time_expired_body), findsOneWidget);
  });

  // The countdown shows whole seconds: under one second it reads 00:00.
  // The charge expires then, not a second later.
  testWidgets('the charge expires when the countdown reads 00:00', (
    tester,
  ) async {
    now = _expiry.subtract(const Duration(milliseconds: 1500));
    await open(tester);
    expect(notice(), findsNothing);

    now = _expiry.subtract(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));
    await frames(tester);

    expect(notice(), findsOneWidget);
  });

  testWidgets('a charge that expired before it opens shows the notice too', (
    tester,
  ) async {
    now = _expiry.add(const Duration(minutes: 5));
    await open(tester);

    expect(tester.takeException(), isNull);
    expect(notice(), findsOneWidget);
  });

  // The notice must be read and acted on: only its button closes it, and
  // the button leaves the expired charge.
  testWidgets('a tap outside, a drag, or the system back keep the notice', (
    tester,
  ) async {
    now = _expiry.add(const Duration(minutes: 5));
    await open(tester);

    await tester.tapAt(const Offset(20, 120));
    await frames(tester);
    expect(notice(), findsOneWidget);

    await tester.drag(notice(), const Offset(0, 500));
    await frames(tester);
    expect(notice(), findsOneWidget);

    await tester.binding.handlePopRoute();
    await frames(tester);
    expect(notice(), findsOneWidget);
    expect(find.byType(ValidPixPaymentScreen), findsOneWidget);
  });

  testWidgets('its back button closes it and leaves the charge', (
    tester,
  ) async {
    now = _expiry.add(const Duration(minutes: 5));
    await open(tester);

    await tester.tap(find.text(t.common_back));
    await frames(tester);

    expect(notice(), findsNothing);
    expect(find.byType(ValidPixPaymentScreen), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });
}

/// Pumps frames for the routes and the sheet. The countdown ticks each
/// second, so `pumpAndSettle` would not end.
Future<void> frames(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
