import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/entities/favorite_payer.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/repositories/favorite_payers_repository.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/controllers/favorite_payers_controller.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/controllers/own_payer_controller.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/providers/favorite_payers_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/deposit/pix_deposit_gate_screen.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/fake_core_sync_helpers.dart';
import '../check_digit_core_sync_helpers.dart';

class _FakeRepo implements FavoritePayersRepository {
  final List<FavoritePayer> items = [
    const FavoritePayer(id: 1, label: 'Ana', cpf: '52998224725'),
  ];

  @override
  Future<List<FavoritePayer>> getAll() async => [...items];
  @override
  Future<FavoritePayerSaveError?> save(FavoritePayer payer) async => null;
  @override
  Future<void> delete(int id) async => items.removeWhere((p) => p.id == id);
  @override
  Future<bool> cpfExists(String cpf, {int? excludingId}) async => false;
  @override
  Future<void> clearAll() async {}
}

void main() {
  useCoreSyncHelpers(const CheckDigitCoreSyncHelpers());

  late SharedPreferences prefs;

  Future<void> open(
    WidgetTester tester,
    Map<String, Object> stored, {
    String location = '/pix/deposit/cpf',
  }) async {
    SharedPreferences.setMockInitialValues(stored);
    prefs = await SharedPreferences.getInstance();
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/pix/deposit/cpf',
          builder: (_, _) => const PixDepositGateScreen(),
        ),
        GoRoute(
          path: '/pix/deposit/notice',
          builder: (_, _) => const PixDepositNoticeScreen(),
        ),
        GoRoute(
          path: '/pix/deposit',
          builder: (_, _) => const Scaffold(body: Text('deposit amount')),
        ),
        GoRoute(
          path: '/favorite-payers',
          builder: (_, _) => const Scaffold(body: Text('favorite payers')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          favoritePayersRepositoryProvider.overrideWithValue(_FakeRepo()),
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

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));

  bool continueEnabled(WidgetTester tester) =>
      tester.widget<PrimaryButton>(find.byType(PrimaryButton)).isEnabled;

  final missing = find.text('Cadastre seu CPF/CNPJ');

  group('before the first deposit', () {
    testWidgets('shows the document of my user', (tester) async {
      await open(tester, {'favorite_payer_own_id': 1});

      expect(find.text('529.982.247-25'), findsOneWidget);
      expect(find.text('Ana · Meu usuário'), findsOneWidget);
      expect(missing, findsNothing);
    });

    testWidgets('continues to the deposit after the notice', (tester) async {
      await open(tester, {'favorite_payer_own_id': 1});
      expect(continueEnabled(tester), isFalse);

      final acknowledge = find.text('Li e entendi o aviso.');
      await tester.scrollUntilVisible(
        acknowledge,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(acknowledge);
      await settle(tester);
      expect(continueEnabled(tester), isTrue);
      await tester.tap(find.text('Continuar'));
      await settle(tester);

      expect(find.text('deposit amount'), findsOneWidget);
      expect(prefs.getBool('pix_deposit_ownership_notice'), isTrue);
    });

    testWidgets('without my user stays empty, warns and does not continue', (
      tester,
    ) async {
      await open(tester, {
        'pix_deposit_tax_id': '39053344705',
        'pix_deposit_ownership_notice': true,
      });

      // The CPF copy of older versions never shows.
      expect(find.text('390.533.447-05'), findsNothing);
      expect(find.text('Nenhum pagador marcado como "Meu usuário".'), findsOne);
      expect(missing, findsOneWidget);
      expect(continueEnabled(tester), isFalse);

      await tester.tap(find.text('Ir para Pagadores favoritos'));
      await settle(tester);
      expect(find.text('favorite payers'), findsOneWidget);
    });

    testWidgets('drops a my user deleted while it is open', (tester) async {
      await open(tester, {
        'favorite_payer_own_id': 1,
        'pix_deposit_ownership_notice': true,
      });
      expect(continueEnabled(tester), isTrue);

      await container(
        tester,
      ).read(favoritePayersControllerProvider.notifier).delete(1);
      await settle(tester);

      expect(find.text('529.982.247-25'), findsNothing);
      expect(missing, findsOneWidget);
      expect(continueEnabled(tester), isFalse);
    });

    testWidgets('takes a my user marked while it is open', (tester) async {
      await open(tester, {});
      expect(missing, findsOneWidget);

      await container(tester).read(ownPayerIdProvider.notifier).mark(1);
      await settle(tester);

      expect(find.text('529.982.247-25'), findsOneWidget);
      expect(missing, findsNothing);
    });
  });

  group('the notice screen', () {
    testWidgets('shows the document of my user', (tester) async {
      await open(tester, {
        'favorite_payer_own_id': 1,
      }, location: '/pix/deposit/notice');

      expect(find.text('529.982.247-25'), findsOneWidget);
      expect(find.text('Alterar pagador'), findsOneWidget);
    });

    testWidgets('without my user warns instead of the old CPF', (tester) async {
      await open(tester, {
        'pix_deposit_tax_id': '39053344705',
      }, location: '/pix/deposit/notice');

      expect(find.text('390.533.447-05'), findsNothing);
      expect(missing, findsOneWidget);
      expect(find.text('Alterar pagador'), findsNothing);
    });
  });
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
