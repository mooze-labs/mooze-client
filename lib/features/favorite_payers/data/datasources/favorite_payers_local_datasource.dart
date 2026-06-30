import 'package:drift/drift.dart' show Value;
import 'package:mooze_mobile/database/database.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/entities/favorite_payer.dart';

class FavoritePayersLocalDataSource {
  final AppDatabase _db;

  FavoritePayersLocalDataSource(this._db);

  Future<List<FavoritePayer>> getAll() async {
    final rows = await _db.getAllFavoritePayers();
    return rows
        .map((r) => FavoritePayer(id: r.id, label: r.label, cpf: r.cpf))
        .toList(growable: false);
  }

  Future<void> insert(String label, String cpf) => _db.insertFavoritePayer(
    FavoritePayerEntriesCompanion.insert(label: label, cpf: cpf),
  );

  Future<void> update(int id, String label, String cpf) =>
      _db.updateFavoritePayerById(
        id,
        FavoritePayerEntriesCompanion(label: Value(label), cpf: Value(cpf)),
      );

  Future<void> delete(int id) => _db.deleteFavoritePayer(id);

  Future<bool> cpfExists(String cpf, {int? excludingId}) =>
      _db.favoritePayerCpfExists(cpf, excludingId: excludingId);

  Future<void> clearAll() => _db.deleteAllFavoritePayers();
}
