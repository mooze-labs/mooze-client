import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/entities/favorite_payer.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/repositories/favorite_payers_repository.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/controllers/favorite_payers_controller.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/controllers/own_payer_controller.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/providers/favorite_payers_providers.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/fake_core_sync_helpers.dart';

/// Payers in memory. A save strips the CPF mask, and a save without an id
/// gets the next id, as the core store does.
class _MemoryRepo implements FavoritePayersRepository {
  _MemoryRepo(this.items);

  List<FavoritePayer> items;

  @override
  Future<List<FavoritePayer>> getAll() async => List.of(items);

  @override
  Future<FavoritePayerSaveError?> save(FavoritePayer input) async {
    final payer = input.copyWith(cpf: input.cpf.replaceAll(RegExp(r'\D'), ''));
    final id = payer.id;
    if (id == null) {
      final next = items.fold(0, (max, p) => p.id! > max ? p.id! : max) + 1;
      items = [payer.copyWith(id: next), ...items];
    } else {
      items = [for (final p in items) p.id == id ? payer : p];
    }
    return null;
  }

  @override
  Future<void> delete(int id) async =>
      items = items.where((p) => p.id != id).toList();

  @override
  Future<bool> cpfExists(String cpf, {int? excludingId}) async => false;

  @override
  Future<void> clearAll() async => items = [];
}

const _ana = FavoritePayer(id: 1, label: 'Ana', cpf: '52998224725');
const _bruno = FavoritePayer(id: 2, label: 'Bruno', cpf: '11144477735');

void main() {
  useCoreSyncHelpers();

  late SharedPreferences prefs;
  late _MemoryRepo repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = _MemoryRepo([_bruno, _ana]);
  });

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        favoritePayersRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(c.dispose);
    c.listen(ownFavoritePayerProvider, (_, _) {});
    return c;
  }

  Future<FavoritePayer?> own(ProviderContainer c) =>
      c.read(ownFavoritePayerProvider.future);

  test('no payer is my user until the user marks one', () async {
    expect(await own(container()), isNull);
  });

  test('the mark survives a new session', () async {
    await container().read(ownPayerIdProvider.notifier).mark(1);

    expect(await own(container()), _ana);
  });

  test('a second mark replaces the first', () async {
    final c = container();

    await c.read(ownPayerIdProvider.notifier).mark(1);
    await c.read(ownPayerIdProvider.notifier).mark(2);

    expect(await own(c), _bruno);
  });

  test('removing the mark brings back the question', () async {
    final c = container();
    await c.read(ownPayerIdProvider.notifier).mark(1);

    await c.read(ownPayerIdProvider.notifier).unmark();

    expect(await own(c), isNull);
    expect(await own(container()), isNull);
  });

  test('a new document of my user reaches the next deposit', () async {
    final c = container();
    await c.read(ownPayerIdProvider.notifier).mark(1);

    await c
        .read(favoritePayersControllerProvider.notifier)
        .save(id: 1, label: 'Ana', cpf: '11222333000181');

    expect((await own(c))?.cpf, '11222333000181');
  });

  test('deleting my user clears the mark', () async {
    final c = container();
    await c.read(ownPayerIdProvider.notifier).mark(1);

    await c.read(favoritePayersControllerProvider.notifier).delete(1);

    expect(c.read(ownPayerIdProvider), isNull);
    // A payer saved later never takes over the mark, even with the same id.
    repo.items = [
      const FavoritePayer(id: 1, label: 'Carla', cpf: '39053344705'),
    ];
    expect(await own(container()), isNull);
  });

  test('deleting another payer keeps the mark', () async {
    final c = container();
    await c.read(ownPayerIdProvider.notifier).mark(1);

    await c.read(favoritePayersControllerProvider.notifier).delete(2);

    expect(await own(c), _ana);
  });

  group('the order of the lists', () {
    const carla = FavoritePayer(id: 3, label: 'Carla', cpf: '39053344705');

    test('puts my user first and keeps the others in order', () {
      expect(ownPayerFirst([_bruno, _ana, carla], 1), [_ana, _bruno, carla]);
      expect(ownPayerFirst([_bruno, _ana, carla], 3), [carla, _bruno, _ana]);
    });

    test('keeps the order without my user in the list', () {
      expect(ownPayerFirst([_bruno, _ana], null), [_bruno, _ana]);
      expect(ownPayerFirst([_bruno, _ana], 99), [_bruno, _ana]);
      expect(ownPayerFirst([_bruno, _ana], 2), [_bruno, _ana]);
    });

    test('follows the mark', () async {
      final c = container();
      c.listen(orderedFavoritePayersProvider, (_, _) {});
      await c.read(favoritePayersControllerProvider.future);
      List<FavoritePayer>? listed() =>
          c.read(orderedFavoritePayersProvider).valueOrNull;
      expect(listed(), [_bruno, _ana]);

      await c.read(ownPayerIdProvider.notifier).mark(1);
      expect(listed(), [_ana, _bruno]);

      await c.read(ownPayerIdProvider.notifier).unmark();
      expect(listed(), [_bruno, _ana]);
    });
  });

  group('a payer saved as my user', () {
    test('becomes my user', () async {
      final c = container();

      await c
          .read(favoritePayersControllerProvider.notifier)
          .save(label: 'Eu', cpf: '390.533.447-05', markAsOwn: true);

      expect(
        await own(c),
        const FavoritePayer(id: 3, label: 'Eu', cpf: '39053344705'),
      );
    });

    test('without the option leaves the mark alone', () async {
      final c = container();
      await c.read(ownPayerIdProvider.notifier).mark(1);

      await c
          .read(favoritePayersControllerProvider.notifier)
          .save(label: 'Carla', cpf: '39053344705');

      expect(await own(c), _ana);
    });
  });
}
