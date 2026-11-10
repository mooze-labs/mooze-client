import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/entities/favorite_payer.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/repositories/favorite_payers_repository.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/providers/favorite_payers_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/receive/pix_receive_screen.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/pix_charge_payer.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/fake_core_sync_helpers.dart';

class _OnePayer implements FavoritePayersRepository {
  @override
  Future<List<FavoritePayer>> getAll() async => const [
    FavoritePayer(id: 1, label: 'Ana', cpf: '52998224725'),
  ];
  @override
  Future<FavoritePayerSaveError?> save(FavoritePayer payer) async => null;
  @override
  Future<void> delete(int id) async {}
  @override
  Future<bool> cpfExists(String cpf, {int? excludingId}) async => false;
  @override
  Future<void> clearAll() async {}
}

void main() {
  useCoreSyncHelpers();

  group('the payer of a charge', () {
    test('travels in the query of the deposit routes', () {
      expect(PixChargePayer.someoneElse.query, '?payer=other');
      expect(PixChargePayer.self.query, '');
      expect(
        PixChargePayer.fromQuery({'payer': 'other'}),
        PixChargePayer.someoneElse,
      );
      // A route without the parameter stays the user's own deposit.
      expect(PixChargePayer.fromQuery({}), PixChargePayer.self);
    });
  });

  /// The route that the last tap opened.
  String? opened;

  Future<void> open(WidgetTester tester, Map<String, Object> stored) async {
    opened = null;
    SharedPreferences.setMockInitialValues(stored);
    final prefs = await SharedPreferences.getInstance();
    GoRoute stub(String path) => GoRoute(
      path: path,
      builder: (_, state) {
        opened = state.uri.toString();
        return Scaffold(body: Text('opened $path'));
      },
    );
    final router = GoRouter(
      initialLocation: '/pix/receive',
      routes: [
        GoRoute(
          path: '/pix/receive',
          builder: (_, _) => const PixReceiveScreen(),
        ),
        stub('/pix/deposit'),
        stub('/pix/deposit/cpf'),
        stub('/favorite-payers'),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          favoritePayersRepositoryProvider.overrideWithValue(_OnePayer()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('pt'),
          builder: (context, child) =>
              Theme(data: AppTheme.darkTheme(context), child: child!),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> tapAndSettle(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await settle(tester);
  }

  testWidgets('a QR Code charge for someone else opens the deposit steps', (
    tester,
  ) async {
    await open(tester, {});

    await tapAndSettle(tester, 'Cobrar com QR Code');

    expect(opened, '/pix/deposit?payer=other');
  });

  group('my own deposit', () {
    testWidgets('without my user asks to register it first', (tester) async {
      // Older versions counted this as ready to deposit.
      await open(tester, {
        'pix_deposit_tax_id': '39053344705',
        'pix_deposit_ownership_notice': true,
      });

      await tapAndSettle(tester, 'Depositar');

      expect(opened, isNull);
      expect(find.text('Cadastre seu CPF/CNPJ'), findsOneWidget);

      await tapAndSettle(tester, 'Ir para Pagadores favoritos');
      expect(opened, '/favorite-payers');
    });

    testWidgets('with my user opens the notice before the first deposit', (
      tester,
    ) async {
      await open(tester, {'favorite_payer_own_id': 1});

      await tapAndSettle(tester, 'Depositar');

      expect(opened, '/pix/deposit/cpf');
    });

    testWidgets('with my user and the notice read opens the deposit', (
      tester,
    ) async {
      await open(tester, {
        'favorite_payer_own_id': 1,
        'pix_deposit_ownership_notice': true,
      });

      await tapAndSettle(tester, 'Depositar');

      expect(opened, '/pix/deposit');
    });
  });
}

/// Pumps frames for the routes and the sheet. The screen has shimmer
/// animations, so `pumpAndSettle` never ends.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
