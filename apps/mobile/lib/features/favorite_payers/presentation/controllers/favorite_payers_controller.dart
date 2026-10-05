import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/entities/favorite_payer.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/repositories/favorite_payers_repository.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/providers/favorite_payers_providers.dart';

export 'package:mooze_mobile/features/favorite_payers/domain/repositories/favorite_payers_repository.dart'
    show FavoritePayerSaveError;

class FavoritePayersController extends AsyncNotifier<List<FavoritePayer>> {
  FavoritePayersRepository get _repo =>
      ref.read(favoritePayersRepositoryProvider);

  @override
  Future<List<FavoritePayer>> build() => _repo.getAll();

  /// Saves a payer. The core strips the CPF mask, trims the label and
  /// refuses a CPF that another payer has.
  Future<FavoritePayerSaveError?> save({
    int? id,
    required String label,
    required String cpf,
  }) async {
    final error =
        await _repo.save(FavoritePayer(id: id, label: label, cpf: cpf));
    if (error != null) return error;
    state = AsyncData(await _repo.getAll());
    return null;
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    state = AsyncData(await _repo.getAll());
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repo.getAll);
  }
}

final favoritePayersControllerProvider =
    AsyncNotifierProvider<FavoritePayersController, List<FavoritePayer>>(
      FavoritePayersController.new,
    );
