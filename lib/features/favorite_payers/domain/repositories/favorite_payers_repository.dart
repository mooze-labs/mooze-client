import 'package:mooze_mobile/features/favorite_payers/domain/entities/favorite_payer.dart';

/// Why a favorite payer save was refused.
enum FavoritePayerSaveError { duplicateCpf }

abstract class FavoritePayersRepository {
  /// Every payer, newest first.
  Future<List<FavoritePayer>> getAll();

  /// Inserts (`payer.id` null) or updates a payer. Strips the CPF mask and
  /// trims the label. Returns the refusal reason, or null when saved.
  Future<FavoritePayerSaveError?> save(FavoritePayer payer);

  Future<void> delete(int id);

  Future<bool> cpfExists(String cpf, {int? excludingId});

  Future<void> clearAll();
}
