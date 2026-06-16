import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/entities/favorite_payer.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/repositories/favorite_payers_repository.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/providers/favorite_payers_providers.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/screens/favorite_payers_screen.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/app_extra_colors.dart';
import 'package:shimmer/shimmer.dart';

class _FakeRepo implements FavoritePayersRepository {
  _FakeRepo({this.items = const [], this.throwOnGet = false, this.hang = false});

  final List<FavoritePayer> items;
  final bool throwOnGet;
  final bool hang;

  @override
  Future<List<FavoritePayer>> getAll() {
    if (hang) return Completer<List<FavoritePayer>>().future;
    if (throwOnGet) return Future.error(Exception('boom'));
    return Future.value(items);
  }

  @override
  Future<void> save(FavoritePayer payer) async {}
  @override
  Future<void> delete(int id) async {}
  @override
  Future<bool> cpfExists(String cpf, {int? excludingId}) async => false;
  @override
  Future<void> clearAll() async {}
}

Widget _app(FavoritePayersRepository repo) => ProviderScope(
  overrides: [favoritePayersRepositoryProvider.overrideWithValue(repo)],
  child: MaterialApp(
    theme: ThemeData.dark().copyWith(extensions: const [AppExtraColors.dark]),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: const FavoritePayersScreen(),
  ),
);

void main() {
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

  testWidgets('error state shows the message and retry', (tester) async {
    await tester.pumpWidget(_app(_FakeRepo(throwOnGet: true)));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't load payers"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
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
}
