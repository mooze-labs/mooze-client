import 'package:mooze_mobile/features/favorite_payers/data/datasources/favorite_payers_local_datasource.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/entities/favorite_payer.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/repositories/favorite_payers_repository.dart';

class FavoritePayersRepositoryImpl implements FavoritePayersRepository {
  final FavoritePayersLocalDataSource _dataSource;

  FavoritePayersRepositoryImpl(this._dataSource);

  @override
  Future<List<FavoritePayer>> getAll() => _dataSource.getAll();

  @override
  Future<void> save(FavoritePayer payer) {
    final id = payer.id;
    return id == null
        ? _dataSource.insert(payer.label, payer.cpf)
        : _dataSource.update(id, payer.label, payer.cpf);
  }

  @override
  Future<void> delete(int id) => _dataSource.delete(id);

  @override
  Future<bool> cpfExists(String cpf, {int? excludingId}) =>
      _dataSource.cpfExists(cpf, excludingId: excludingId);

  @override
  Future<void> clearAll() => _dataSource.clearAll();
}
