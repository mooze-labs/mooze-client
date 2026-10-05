import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/entities/favorite_payer.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/repositories/favorite_payers_repository.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/controllers/favorite_payers_controller.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/providers/favorite_payers_providers.dart';

/// In-memory repository. It mimics the core rules that the controller
/// relies on: mask stripping, label trimming, duplicate refusal.
class _MemoryRepo implements FavoritePayersRepository {
  final List<FavoritePayer> rows = [];
  var _nextId = 1;

  String _digits(String cpf) => cpf.replaceAll(RegExp(r'[^0-9]'), '');

  @override
  Future<List<FavoritePayer>> getAll() async => List.of(rows.reversed);

  @override
  Future<FavoritePayerSaveError?> save(FavoritePayer payer) async {
    final cpf = _digits(payer.cpf);
    if (await cpfExists(cpf, excludingId: payer.id)) {
      return FavoritePayerSaveError.duplicateCpf;
    }
    final row = FavoritePayer(
      id: payer.id ?? _nextId++,
      label: payer.label.trim(),
      cpf: cpf,
    );
    rows.removeWhere((r) => r.id == row.id);
    rows.add(row);
    return null;
  }

  @override
  Future<void> delete(int id) async => rows.removeWhere((r) => r.id == id);

  @override
  Future<bool> cpfExists(String cpf, {int? excludingId}) async =>
      rows.any((r) => r.cpf == _digits(cpf) && r.id != excludingId);

  @override
  Future<void> clearAll() async => rows.clear();
}

ProviderContainer _container(FavoritePayersRepository repo) {
  final container = ProviderContainer(
    overrides: [favoritePayersRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late _MemoryRepo repo;
  setUp(() => repo = _MemoryRepo());

  test('starts empty', () async {
    final c = _container(repo);
    expect(await c.read(favoritePayersControllerProvider.future), isEmpty);
  });

  test('save stores the payer and refreshes the state', () async {
    final c = _container(repo);
    final notifier = c.read(favoritePayersControllerProvider.notifier);
    await c.read(favoritePayersControllerProvider.future);

    final err = await notifier.save(label: ' João ', cpf: '529.982.247-25');

    expect(err, isNull);
    final list = c.read(favoritePayersControllerProvider).value!;
    expect(list.single.cpf, '52998224725');
    expect(list.single.label, 'João');
  });

  test('save returns the refusal and keeps the state', () async {
    final c = _container(repo);
    final notifier = c.read(favoritePayersControllerProvider.notifier);
    await c.read(favoritePayersControllerProvider.future);

    await notifier.save(label: 'João', cpf: '52998224725');
    final dup = await notifier.save(label: 'Outro', cpf: '529.982.247-25');

    expect(dup, FavoritePayerSaveError.duplicateCpf);
    expect(c.read(favoritePayersControllerProvider).value, hasLength(1));
  });

  test('editing the same row passes its id', () async {
    final c = _container(repo);
    final notifier = c.read(favoritePayersControllerProvider.notifier);
    await c.read(favoritePayersControllerProvider.future);

    await notifier.save(label: 'João', cpf: '52998224725');
    final id = c.read(favoritePayersControllerProvider).value!.single.id!;

    final err = await notifier.save(id: id, label: 'João S.', cpf: '52998224725');

    expect(err, isNull);
    final updated = c.read(favoritePayersControllerProvider).value!.single;
    expect(updated.label, 'João S.');
    expect(updated.cpf, '52998224725');
  });

  test('delete removes the payer', () async {
    final c = _container(repo);
    final notifier = c.read(favoritePayersControllerProvider.notifier);
    await c.read(favoritePayersControllerProvider.future);

    await notifier.save(label: 'João', cpf: '52998224725');
    final id = c.read(favoritePayersControllerProvider).value!.single.id!;

    await notifier.delete(id);

    expect(c.read(favoritePayersControllerProvider).value, isEmpty);
  });
}
