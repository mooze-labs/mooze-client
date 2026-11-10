import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/entities/favorite_payer.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/repositories/favorite_payers_repository.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/controllers/favorite_payers_controller.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/providers/favorite_payers_providers.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/pix_charge_payer.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/presentation/cpf_input_screen.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/presentation/pix_cpf_gate.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:mooze_mobile/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/fake_core_sync_helpers.dart';

/// Favorites kept in memory, like the store of mooze-core.
class _FakeRepo implements FavoritePayersRepository {
  _FakeRepo(List<FavoritePayer> items) : items = [...items];
  final List<FavoritePayer> items;

  @override
  Future<List<FavoritePayer>> getAll() async => [...items];
  @override
  Future<FavoritePayerSaveError?> save(FavoritePayer payer) async {
    final index = items.indexWhere((p) => p.id == payer.id);
    items[index] = payer;
    return null;
  }

  @override
  Future<void> delete(int id) async => items.removeWhere((p) => p.id == id);
  @override
  Future<bool> cpfExists(String cpf, {int? excludingId}) async => false;
  @override
  Future<void> clearAll() async {}
}

const _ana = FavoritePayer(id: 1, label: 'Ana', cpf: '52998224725');
const _bruno = FavoritePayer(id: 2, label: 'Bruno', cpf: '11144477735');

/// A CPF copy that older versions kept apart from the favorites.
const _legacyTaxId = '39053344705';

void main() {
  useCoreSyncHelpers();

  late SharedPreferences prefs;
  late _FakeRepo repo;
  PixCpfGateResult? result;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'pix_deposit_tax_id': _legacyTaxId,
    });
    prefs = await SharedPreferences.getInstance();
    repo = _FakeRepo(const [_bruno, _ana]);
    result = null;
  });

  /// A screen whose button runs the gate for [payer].
  Widget launcher(PixChargePayer payer) => ProviderScope(
    overrides: [
      favoritePayersRepositoryProvider.overrideWithValue(repo),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      builder: (context, child) =>
          Theme(data: AppTheme.darkTheme(context), child: child!),
      home: Consumer(
        builder: (context, ref, _) => Scaffold(
          body: TextButton(
            onPressed: () async =>
                result = await PixCpfGate.ensure(context, ref, payer: payer),
            child: const Text('deposit'),
          ),
        ),
      ),
    ),
  );

  Future<void> tapDeposit(WidgetTester tester) async {
    await tester.tap(find.text('deposit'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> run(WidgetTester tester, PixChargePayer payer) async {
    await tester.pumpWidget(launcher(payer));
    await tapDeposit(tester);
  }

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(Consumer)));

  final requiredSheet = find.text('Register your CPF/CNPJ');

  group('my own deposit', () {
    testWidgets('uses the document of my user', (tester) async {
      await prefs.setInt('favorite_payer_own_id', 2);

      await run(tester, PixChargePayer.self);

      expect(find.byType(CpfInputScreen), findsNothing);
      expect(result?.taxIdNumber, _bruno.cpf);
    });

    testWidgets('without my user asks to register it and stops', (
      tester,
    ) async {
      await run(tester, PixChargePayer.self);

      expect(requiredSheet, findsOneWidget);
      expect(find.byType(CpfInputScreen), findsNothing);
      // Closing the sheet ends the step. The old CPF copy never fills it.
      await tester.tap(find.byTooltip('Close'));
      await tester.pump(const Duration(seconds: 1));
      expect(result?.cancelled, isTrue);
      expect(result?.taxIdNumber, isNull);
    });

    testWidgets('a mark of a removed payer reads as no mark', (tester) async {
      await prefs.setInt('favorite_payer_own_id', 99);

      await run(tester, PixChargePayer.self);

      expect(requiredSheet, findsOneWidget);
    });

    testWidgets('never uses the document of a deleted my user', (tester) async {
      await prefs.setInt('favorite_payer_own_id', 2);
      await run(tester, PixChargePayer.self);
      expect(result?.taxIdNumber, _bruno.cpf);

      await container(
        tester,
      ).read(favoritePayersControllerProvider.notifier).delete(2);
      await tapDeposit(tester);

      expect(requiredSheet, findsOneWidget);
      expect(find.byType(CpfInputScreen), findsNothing);
    });

    testWidgets('takes a document changed in the favorites', (tester) async {
      await prefs.setInt('favorite_payer_own_id', 2);
      await run(tester, PixChargePayer.self);

      await container(tester)
          .read(favoritePayersControllerProvider.notifier)
          .save(id: 2, label: 'Bruno', cpf: '86288366757');
      await tapDeposit(tester);

      expect(result?.taxIdNumber, '86288366757');
    });

    testWidgets('a document that fails the check reads as no payer', (
      tester,
    ) async {
      repo.items.add(const FavoritePayer(id: 3, label: 'Eu', cpf: '1234'));
      await prefs.setInt('favorite_payer_own_id', 3);

      await run(tester, PixChargePayer.self);

      expect(requiredSheet, findsOneWidget);
    });
  });

  testWidgets('a charge for someone else asks with an empty field', (
    tester,
  ) async {
    await prefs.setInt('favorite_payer_own_id', 2);

    await run(tester, PixChargePayer.someoneElse);

    // Neither my user nor the old CPF copy reaches another person's charge.
    expect(find.byType(CpfInputScreen), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.controller!.text, isEmpty);
  });
}
