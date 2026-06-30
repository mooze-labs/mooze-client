import 'package:mooze_mobile/features/favorite_payers/domain/entities/favorite_payer.dart';

abstract class FavoritePayersRepository {
  Future<List<FavoritePayer>> getAll();

  Future<void> save(FavoritePayer payer);

  Future<void> delete(int id);

  Future<bool> cpfExists(String cpf, {int? excludingId});

  Future<void> clearAll();
}
