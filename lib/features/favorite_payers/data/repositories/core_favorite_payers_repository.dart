import 'package:mooze_core_bridge/mooze_core_bridge.dart';

import 'package:mooze_mobile/features/favorite_payers/domain/entities/favorite_payer.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/repositories/favorite_payers_repository.dart';
import 'package:mooze_mobile/features/pix/data/mappers/core_pix_mapper.dart';

/// [FavoritePayersRepository] backed by the mooze-core store.
class CoreFavoritePayersRepository implements FavoritePayersRepository {
  CoreFavoritePayersRepository(this._core);

  final Future<MoozeCore> _core;

  @override
  Future<List<FavoritePayer>> getAll() async {
    final list = await (await _core).favoritePayersList();
    return list.map(favoritePayerFromDto).toList(growable: false);
  }

  @override
  Future<FavoritePayerSaveError?> save(FavoritePayer payer) async {
    final id = payer.id;
    final error = await (await _core).favoritePayerSave(
      id: id == null ? null : BigInt.from(id),
      label: payer.label,
      cpf: payer.cpf,
    );
    return switch (error) {
      null => null,
      FavoritePayerSaveErrorDto.duplicateCpf =>
        FavoritePayerSaveError.duplicateCpf,
    };
  }

  @override
  Future<void> delete(int id) async =>
      (await _core).favoritePayerDelete(id: BigInt.from(id));

  @override
  Future<bool> cpfExists(String cpf, {int? excludingId}) async =>
      (await _core).favoritePayerCpfExists(
        cpf: cpf,
        excludingId: excludingId == null ? null : BigInt.from(excludingId),
      );

  @override
  Future<void> clearAll() async => (await _core).favoritePayersClear();
}
