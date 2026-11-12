import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_receive_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_send_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/history/pix_hub_history_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_transaction_tile.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

PixDeposit _deposit(String id, DepositStatus status, {int day = 11}) =>
    PixDeposit(
      depositId: id,
      pixKey: 'chave',
      asset: Asset.depix,
      amountInCents: 10000,
      network: 'liquid',
      status: status,
      createdAt: DateTime(2026, 11, day, 14, 32),
    );

void main() {
  /// Opens the hub history with [deposits]. The routes record what opens.
  Future<List<String>> open(
    WidgetTester tester,
    List<PixDeposit> deposits,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final opened = <String>[];
    final router = GoRouter(
      initialLocation: '/pix/history',
      routes: [
        GoRoute(
          path: '/pix/history',
          builder: (_, _) => const PixHubHistoryScreen(),
        ),
        GoRoute(
          path: '/depix/transactions/details',
          builder: (_, state) {
            opened.add('details ${(state.extra as PixDeposit).depositId}');
            return const Scaffold(body: Text('deposit details'));
          },
        ),
        GoRoute(
          path: '/pix/payment/:id',
          builder: (_, state) {
            opened.add('payment ${state.pathParameters['id']}');
            return const Scaffold(body: Text('payment'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pixDepositHistoryProvider.overrideWith(
            (ref) async => Right(deposits),
          ),
          // The list of the hub reads the deposits above, as in the app.
          sharedPreferencesProvider.overrideWithValue(prefs),
          pixPendingWithdrawalSyncProvider.overrideWith((ref) async {}),
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
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    return opened;
  }

  Future<void> tapFirstDeposit(WidgetTester tester) async {
    await tester.tap(find.byType(PixTransactionTile).first);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  // A deposit opens the same details as in the Pix history, so both
  // histories show a deposit the same way.
  for (final status in [DepositStatus.finished, DepositStatus.pending]) {
    testWidgets('a ${status.name} deposit opens the details of the Pix '
        'history', (tester) async {
      // The newest deposit lists first, and opens with its own details.
      final opened = await open(tester, [
        _deposit('d-old', DepositStatus.finished, day: 1),
        _deposit('d-new', status, day: 11),
      ]);

      await tapFirstDeposit(tester);

      expect(opened, ['details d-new']);
      expect(find.text('deposit details'), findsOneWidget);
    });
  }
}
