import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/entities/favorite_payer.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/repositories/favorite_payers_repository.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/providers/favorite_payers_providers.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/screens/favorite_payer_edit_screen.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/screens/favorite_payers_screen.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:mooze_mobile/themes/app_extra_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import '../../shared/fake_core_sync_helpers.dart';

class _FakeRepo implements FavoritePayersRepository {
  _FakeRepo({
    List<FavoritePayer> items = const [],
    this.throwOnGet = false,
    this.hang = false,
  }) : items = [...items];

  final List<FavoritePayer> items;
  final bool throwOnGet;
  final bool hang;

  /// How many saves reached the store.
  int saves = 0;

  /// When set, a save waits for it, like a slow store.
  Completer<void>? slowSave;

  /// When set, a save throws it, like a store failure.
  Object? saveFailure;

  @override
  Future<List<FavoritePayer>> getAll() {
    if (hang) return Completer<List<FavoritePayer>>().future;
    if (throwOnGet) return Future.error(Exception('boom'));
    return Future.value([...items]);
  }

  /// Stores a new payer first, with the next id and the bare digits, as the
  /// core store does.
  @override
  Future<FavoritePayerSaveError?> save(FavoritePayer payer) async {
    saves++;
    await slowSave?.future;
    final failure = saveFailure;
    if (failure != null) throw failure;
    if (payer.id == null) {
      items.insert(
        0,
        payer.copyWith(
          id: items.length + 1,
          cpf: payer.cpf.replaceAll(RegExp(r'\D'), ''),
        ),
      );
    }
    return null;
  }

  @override
  Future<void> delete(int id) async {}
  @override
  Future<bool> cpfExists(String cpf, {int? excludingId}) async => false;
  @override
  Future<void> clearAll() async {}
}

/// Holds the "my user" mark of the screen.
late SharedPreferences _prefs;

Widget _app(
  FavoritePayersRepository repo, {
  Widget home = const FavoritePayersScreen(),
}) => ProviderScope(
  overrides: [
    favoritePayersRepositoryProvider.overrideWithValue(repo),
    sharedPreferencesProvider.overrideWithValue(_prefs),
  ],
  child: MaterialApp(
    theme: ThemeData.dark().copyWith(extensions: const [AppExtraColors.dark]),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: home,
  ),
);

void main() {
  useCoreSyncHelpers();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  testWidgets('loading state shows a shimmer skeleton', (tester) async {
    await tester.pumpWidget(_app(_FakeRepo(hang: true)));
    await tester.pump();
    expect(find.byType(Shimmer), findsWidgets);
  });

  testWidgets('empty state shows the call to action', (tester) async {
    await tester.pumpWidget(_app(_FakeRepo(items: const [])));
    await tester.pumpAndSettle();
    expect(find.text('No saved payers'), findsOneWidget);
    expect(find.text('Add payer'), findsWidgets);
  });

  group('empty state', () {
    testWidgets('says what payers are for, own deposits first, and pins the '
        'add button at the bottom', (tester) async {
      await tester.pumpWidget(_app(_FakeRepo(items: const [])));
      await tester.pumpAndSettle();

      expect(find.text('Your deposits'), findsOneWidget);
      expect(
        find.text(
          'Add the holder of the account that pays your deposits and mark '
          'them as "My user".',
        ),
        findsOneWidget,
      );
      expect(find.text('People who pay you'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Your deposits')).dy,
        lessThan(tester.getTopLeft(find.text('People who pay you')).dy),
      );
      // One add button, pinned at the bottom as with a list.
      expect(find.byType(PrimaryButton), findsOneWidget);
      expect(
        tester.getBottomLeft(find.byType(PrimaryButton)).dy,
        greaterThan(tester.getBottomLeft(find.text('People who pay you')).dy),
      );
    });

    testWidgets('the preview of the list is decoration for screen readers', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_app(_FakeRepo(items: const [])));
      await tester.pumpAndSettle();

      // The preview shows the badge, but a screen reader skips it.
      expect(find.text('My user'), findsOneWidget);
      expect(find.bySemanticsLabel('My user'), findsNothing);
      expect(find.bySemanticsLabel(RegExp('^No saved payers')), findsOne);
      semantics.dispose();
    });

    testWidgets('the add button opens the editor that offers to mark the '
        'payer as me', (tester) async {
      await tester.pumpWidget(_app(_FakeRepo(items: const [])));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add payer'));
      await tester.pumpAndSettle();

      expect(find.byType(FavoritePayerEditScreen), findsOneWidget);
      expect(find.text('This payer is me'), findsOneWidget);
    });

    testWidgets('fits a 320 pt screen at 200% text', (tester) async {
      tester.view.physicalSize = const Size(320, 640) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(_app(_FakeRepo(items: const [])));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // The text did grow to twice its size.
      expect(
        MediaQuery.textScalerOf(
          tester.element(find.text('Your deposits')),
        ).scale(10),
        20,
      );
    });
  });

  testWidgets('error state shows the message and retry', (tester) async {
    await tester.pumpWidget(_app(_FakeRepo(throwOnGet: true)));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't load payers"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    // Nothing to add to while the payers fail to load.
    expect(find.byType(PrimaryButton), findsNothing);
  });

  testWidgets('data state lists payers with masked CPF', (tester) async {
    await tester.pumpWidget(
      _app(
        _FakeRepo(
          items: const [
            FavoritePayer(id: 1, label: 'João', cpf: '52998224725'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('João'), findsOneWidget);
    expect(find.text('529.982.247-25'), findsOneWidget);
  });

  group('my user', () {
    const payers = [
      FavoritePayer(id: 1, label: 'João', cpf: '52998224725'),
      FavoritePayer(id: 2, label: 'Maria', cpf: '11144477735'),
    ];

    Future<void> openMenuOf(WidgetTester tester, String label) async {
      await tester.tap(
        find.descendant(
          of: find.ancestor(
            of: find.text(label),
            matching: find.byType(InkWell),
          ),
          matching: find.byTooltip('Actions'),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the menu marks a payer as my user', (tester) async {
      await tester.pumpWidget(_app(_FakeRepo(items: payers)));
      await tester.pumpAndSettle();
      expect(find.text('My user'), findsNothing);

      await openMenuOf(tester, 'Maria');
      await tester.tap(find.text('Mark as my user'));
      await tester.pumpAndSettle();

      expect(find.text('My user'), findsOneWidget);
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text('Maria'),
            matching: find.byType(InkWell),
          ),
          matching: find.text('My user'),
        ),
        findsOneWidget,
      );
      expect(_prefs.getInt('favorite_payer_own_id'), 2);
    });

    testWidgets('the same menu removes the mark', (tester) async {
      await _prefs.setInt('favorite_payer_own_id', 1);
      await tester.pumpWidget(_app(_FakeRepo(items: payers)));
      await tester.pumpAndSettle();
      expect(find.text('My user'), findsOneWidget);

      await openMenuOf(tester, 'João');
      await tester.tap(find.text('Unmark as my user'));
      await tester.pumpAndSettle();

      expect(find.text('My user'), findsNothing);
      expect(_prefs.containsKey('favorite_payer_own_id'), isFalse);
    });

    testWidgets('the menu is the glass menu of the app, with remove in the '
        'negative color', (tester) async {
      await _prefs.setInt('favorite_payer_own_id', 1);
      await tester.pumpWidget(_app(_FakeRepo(items: payers)));
      await tester.pumpAndSettle();

      await openMenuOf(tester, 'João');

      expect(find.byType(PopupMenuItem), findsNothing);
      final panel = find.byWidgetPredicate((w) => w is LiquidGlass && w.opaque);
      expect(panel, findsOneWidget);
      for (final label in ['Edit', 'Unmark as my user', 'Remove']) {
        expect(
          find.descendant(of: panel, matching: find.text(label)),
          findsOneWidget,
        );
      }
      final remove = tester.widget<Text>(
        find.descendant(of: panel, matching: find.text('Remove')),
      );
      expect(
        remove.style?.color,
        Theme.of(tester.element(panel)).colorScheme.error,
      );
    });

    testWidgets('remove asks first, once the menu has closed', (tester) async {
      await tester.pumpWidget(_app(_FakeRepo(items: payers)));
      await tester.pumpAndSettle();

      await openMenuOf(tester, 'Maria');
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      // The menu is gone: the only opaque glass left is the confirm
      // dialog, and it names the payer.
      expect(
        find.byWidgetPredicate((w) => w is LiquidGlass && w.opaque),
        findsOneWidget,
      );
      expect(find.byType(GlassAlertDialog), findsOneWidget);
      expect(find.text('Remove Maria from favorite payers?'), findsOneWidget);
    });

    testWidgets('edit opens the editor of that payer', (tester) async {
      await tester.pumpWidget(_app(_FakeRepo(items: payers)));
      await tester.pumpAndSettle();

      await openMenuOf(tester, 'Maria');
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      final editor = tester.widget<FavoritePayerEditScreen>(
        find.byType(FavoritePayerEditScreen),
      );
      expect(editor.initial?.label, 'Maria');
    });
  });

  group('my user in the list', () {
    const payers = [
      FavoritePayer(id: 1, label: 'João', cpf: '52998224725'),
      FavoritePayer(id: 2, label: 'Maria', cpf: '11144477735'),
    ];

    double top(WidgetTester tester, String label) =>
        tester.getTopLeft(find.text(label)).dy;

    testWidgets('comes first', (tester) async {
      await _prefs.setInt('favorite_payer_own_id', 2);
      await tester.pumpWidget(_app(_FakeRepo(items: payers)));
      await tester.pumpAndSettle();

      expect(top(tester, 'Maria'), lessThan(top(tester, 'João')));
    });

    testWidgets('without a mark the store order stays', (tester) async {
      await tester.pumpWidget(_app(_FakeRepo(items: payers)));
      await tester.pumpAndSettle();

      expect(top(tester, 'João'), lessThan(top(tester, 'Maria')));
    });
  });

  group('adding a payer', () {
    const joao = FavoritePayer(id: 1, label: 'João', cpf: '52998224725');

    Future<void> openEditor(WidgetTester tester) async {
      await tester.tap(find.text('Add payer'));
      await tester.pumpAndSettle();
    }

    testWidgets('offers to mark it as me while nobody is my user', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_FakeRepo(items: const [joao])));
      await tester.pumpAndSettle();
      await openEditor(tester);

      await tester.enterText(find.byType(TextField).at(0), 'Eu');
      await tester.enterText(find.byType(TextField).at(1), '39053344705');
      await tester.tap(find.text('This payer is me'));
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(_prefs.getInt('favorite_payer_own_id'), 2);
      expect(find.text('Eu is now your user for deposits.'), findsOneWidget);
      // The new payer is my user, first in the list.
      expect(
        tester.getTopLeft(find.text('Eu')).dy,
        lessThan(tester.getTopLeft(find.text('João')).dy),
      );
      expect(find.text('My user'), findsOneWidget);
    });

    testWidgets('left unchecked saves a payer without the mark', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_FakeRepo(items: const [joao])));
      await tester.pumpAndSettle();
      await openEditor(tester);

      await tester.enterText(find.byType(TextField).at(0), 'Carla');
      await tester.enterText(find.byType(TextField).at(1), '39053344705');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Carla'), findsOneWidget);
      expect(_prefs.containsKey('favorite_payer_own_id'), isFalse);
    });

    Future<void> fillAndSave(WidgetTester tester, String label) async {
      await tester.enterText(find.byType(TextField).at(0), label);
      await tester.enterText(find.byType(TextField).at(1), '39053344705');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
    }

    List<String> fieldTexts(WidgetTester tester) => [
      for (final field in tester.widgetList<TextField>(find.byType(TextField)))
        field.controller!.text,
    ];

    testWidgets('closes the add screen, and the next add starts empty', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_FakeRepo(items: const [joao])));
      await tester.pumpAndSettle();
      await openEditor(tester);

      await fillAndSave(tester, 'Carla');

      expect(find.byType(FavoritePayerEditScreen), findsNothing);
      expect(find.text('Carla'), findsOneWidget);
      await openEditor(tester);
      expect(fieldTexts(tester), ['', '']);
    });

    testWidgets('clears the fields when the screen cannot close', (
      tester,
    ) async {
      final repo = _FakeRepo();
      await tester.pumpWidget(
        _app(repo, home: const FavoritePayerEditScreen()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('This payer is me'));
      await tester.pump();

      await fillAndSave(tester, 'Carla');

      expect(repo.items.single.label, 'Carla');
      expect(find.byType(FavoritePayerEditScreen), findsOneWidget);
      expect(fieldTexts(tester), ['', '']);
    });

    testWidgets('a failed save keeps the fields and says so', (tester) async {
      final repo = _FakeRepo(items: const [joao])
        ..saveFailure = Exception('store');
      await tester.pumpWidget(_app(repo));
      await tester.pumpAndSettle();
      await openEditor(tester);

      await fillAndSave(tester, 'Carla');

      expect(find.byType(FavoritePayerEditScreen), findsOneWidget);
      expect(fieldTexts(tester), ['Carla', '390.533.447-05']);
      expect(find.text("Couldn't save the payer. Try again."), findsOneWidget);
      expect(
        tester.widget<PrimaryButton>(find.byType(PrimaryButton)).isLoading,
        isFalse,
      );
    });

    testWidgets('a second submit during the save saves once', (tester) async {
      final repo = _FakeRepo(items: const [joao])..slowSave = Completer<void>();
      await tester.pumpWidget(_app(repo));
      await tester.pumpAndSettle();
      await openEditor(tester);
      await tester.enterText(find.byType(TextField).at(0), 'Carla');
      await tester.enterText(find.byType(TextField).at(1), '39053344705');

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      repo.slowSave!.complete();
      await tester.pumpAndSettle();

      expect(repo.saves, 1);
      expect(find.byType(FavoritePayerEditScreen), findsNothing);
    });

    testWidgets('does not offer it once a payer is my user', (tester) async {
      await _prefs.setInt('favorite_payer_own_id', 1);
      await tester.pumpWidget(_app(_FakeRepo(items: const [joao])));
      await tester.pumpAndSettle();
      await openEditor(tester);

      expect(find.text('This payer is me'), findsNothing);
    });
  });
}
