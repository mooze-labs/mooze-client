import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/database/database.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/controllers/favorite_payers_controller.dart';
import 'package:mooze_mobile/shared/infra/db/providers.dart';

import '../../shared/database_test_helpers.dart';

ProviderContainer _container(AppDatabase db) {
  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  setUp(() => db = buildInMemoryDatabase());
  tearDown(() async => db.close());

  test('starts empty', () async {
    final c = _container(db);
    expect(await c.read(favoritePayersControllerProvider.future), isEmpty);
  });

  test('save adds a payer, normalising the CPF to digits', () async {
    final c = _container(db);
    final notifier = c.read(favoritePayersControllerProvider.notifier);
    await c.read(favoritePayersControllerProvider.future);

    final err = await notifier.save(label: 'João', cpf: '529.982.247-25');

    expect(err, isNull);
    final list = c.read(favoritePayersControllerProvider).value!;
    expect(list.single.cpf, '52998224725');
    expect(list.single.label, 'João');
  });

  test('save rejects a duplicate CPF (masked or raw)', () async {
    final c = _container(db);
    final notifier = c.read(favoritePayersControllerProvider.notifier);
    await c.read(favoritePayersControllerProvider.future);

    await notifier.save(label: 'João', cpf: '52998224725');
    final dup = await notifier.save(label: 'Outro', cpf: '529.982.247-25');

    expect(dup, FavoritePayerSaveError.duplicateCpf);
    expect(c.read(favoritePayersControllerProvider).value, hasLength(1));
  });

  test('editing the same row keeps its CPF without a false duplicate', () async {
    final c = _container(db);
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
    final c = _container(db);
    final notifier = c.read(favoritePayersControllerProvider.notifier);
    await c.read(favoritePayersControllerProvider.future);

    await notifier.save(label: 'João', cpf: '52998224725');
    final id = c.read(favoritePayersControllerProvider).value!.single.id!;

    await notifier.delete(id);

    expect(c.read(favoritePayersControllerProvider).value, isEmpty);
  });
}
