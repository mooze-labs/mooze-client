import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart';

import 'package:mooze_mobile/features/favorite_payers/data/repositories/core_favorite_payers_repository.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/entities/favorite_payer.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/repositories/favorite_payers_repository.dart';

class _MockCore extends Mock implements MoozeCore {}

void main() {
  late _MockCore core;
  late CoreFavoritePayersRepository repo;

  setUp(() {
    core = _MockCore();
    repo = CoreFavoritePayersRepository(Future.value(core));
  });

  test('getAll maps the core payers', () async {
    when(() => core.favoritePayersList()).thenAnswer(
      (_) async => [
        FavoritePayerDto(
          id: BigInt.from(7),
          label: 'João',
          cpf: '52998224725',
          maskedCpf: '529.982.247-25',
        ),
      ],
    );

    expect(await repo.getAll(), const [
      FavoritePayer(id: 7, label: 'João', cpf: '52998224725'),
    ]);
  });

  test('save inserts with a null id and returns null when saved', () async {
    when(
      () => core.favoritePayerSave(
        id: null,
        label: 'João',
        cpf: '529.982.247-25',
      ),
    ).thenAnswer((_) async => null);

    final error = await repo.save(
      const FavoritePayer(label: 'João', cpf: '529.982.247-25'),
    );

    expect(error, isNull);
  });

  test('save updates by id and maps the duplicate refusal', () async {
    when(
      () => core.favoritePayerSave(
        id: BigInt.from(3),
        label: 'Outro',
        cpf: '52998224725',
      ),
    ).thenAnswer((_) async => FavoritePayerSaveErrorDto.duplicateCpf);

    final error = await repo.save(
      const FavoritePayer(id: 3, label: 'Outro', cpf: '52998224725'),
    );

    expect(error, FavoritePayerSaveError.duplicateCpf);
  });

  test('delete, cpfExists and clearAll reach the core', () async {
    when(() => core.favoritePayerDelete(id: BigInt.from(4)))
        .thenAnswer((_) async {});
    when(
      () => core.favoritePayerCpfExists(
        cpf: '52998224725',
        excludingId: BigInt.from(4),
      ),
    ).thenAnswer((_) async => true);
    when(() => core.favoritePayersClear()).thenAnswer((_) async {});

    await repo.delete(4);
    final exists = await repo.cpfExists('52998224725', excludingId: 4);
    await repo.clearAll();

    expect(exists, isTrue);
    verify(() => core.favoritePayerDelete(id: BigInt.from(4))).called(1);
    verify(() => core.favoritePayersClear()).called(1);
  });
}
