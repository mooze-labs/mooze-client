import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/entities/favorite_payer.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/repositories/favorite_payers_repository.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/providers/favorite_payers_providers.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/presentation/cpf_input_screen.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/app_extra_colors.dart';

class _FakeRepo implements FavoritePayersRepository {
  _FakeRepo(this.items);
  final List<FavoritePayer> items;

  @override
  Future<List<FavoritePayer>> getAll() async => items;
  @override
  Future<void> save(FavoritePayer payer) async {}
  @override
  Future<void> delete(int id) async {}
  @override
  Future<bool> cpfExists(String cpf, {int? excludingId}) async => false;
  @override
  Future<void> clearAll() async {}
}

Widget _app(List<FavoritePayer> favorites) => ProviderScope(
  overrides: [
    favoritePayersRepositoryProvider.overrideWithValue(_FakeRepo(favorites)),
  ],
  child: MaterialApp(
    theme: ThemeData.dark().copyWith(extensions: const [AppExtraColors.dark]),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: const CpfInputScreen(),
  ),
);

/// Builds [n] payers with distinct 11-digit CPFs. Validity is irrelevant here —
/// the carousel/sheet render saved data regardless of CPF check digits.
List<FavoritePayer> manyPayers(int n) => List.generate(
  n,
  (i) => FavoritePayer(id: i + 1, label: 'Payer $i', cpf: '${10000000000 + i}'),
);

void main() {
  const cristian = FavoritePayer(id: 1, label: 'Cristian', cpf: '52998224725');

  testWidgets('renders saved payers as selectable chips', (tester) async {
    await tester.pumpWidget(_app(const [cristian]));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ChoiceChip, 'Cristian'), findsOneWidget);
  });

  testWidgets('tapping a favorite fills the CPF field (no auto-save prompt)', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const [cristian]));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ChoiceChip));
    await tester.pumpAndSettle();

    // Field is populated with the masked CPF...
    expect(find.text('529.982.247-25'), findsOneWidget);
    // ...and because it's already a saved favorite, no save prompt appears.
    expect(find.text('Save this payer'), findsNothing);
  });

  testWidgets('a valid manual CPF reveals the contextual save action', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const []));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '52998224725');
    await tester.pumpAndSettle();

    expect(find.text('Save this payer'), findsOneWidget);
  });

  testWidgets('a valid manual CNPJ is masked and reveals the save action', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const []));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '11222333000181');
    await tester.pumpAndSettle();

    expect(find.text('11.222.333/0001-81'), findsOneWidget);
    expect(find.text('Save this payer'), findsOneWidget);
  });

  testWidgets('no save action for an incomplete CPF', (tester) async {
    await tester.pumpWidget(_app(const []));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '5299822');
    await tester.pumpAndSettle();

    expect(find.text('Save this payer'), findsNothing);
  });

  testWidgets('caps inline chips at 5 and shows "View all" beyond that', (
    tester,
  ) async {
    await tester.pumpWidget(_app(manyPayers(6)));
    await tester.pumpAndSettle();

    // Bounded carousel: only 5 chips inlined regardless of total count.
    expect(find.byType(ChoiceChip), findsNWidgets(5));
    expect(find.text('View all'), findsOneWidget);
  });

  testWidgets('"View all" opens the sheet; selecting fills the CPF field', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(manyPayers(6)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('View all'));
    await tester.pumpAndSettle();

    // Sheet header (distinct from the screen title).
    expect(find.text('Favorite payers'), findsOneWidget);

    // 'Payer 5' lives only in the sheet (carousel shows 0..4).
    await tester.tap(find.text('Payer 5'));
    await tester.pumpAndSettle();

    expect(find.text('100.000.000-05'), findsOneWidget);
  });

  testWidgets('sheet search filters the full list', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(manyPayers(8)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('View all'));
    await tester.pumpAndSettle();

    final search = find.ancestor(
      of: find.byIcon(Icons.search_rounded),
      matching: find.byType(TextField),
    );
    await tester.enterText(search, 'Payer 6');
    await tester.pumpAndSettle();

    // The matching payer's row is shown (scoped to the tile, not the search box).
    expect(find.widgetWithText(ListTile, 'Payer 6'), findsOneWidget);
    // 'Payer 7' is sheet-only and filtered out → gone from the tree.
    expect(find.text('Payer 7'), findsNothing);
  });
}
