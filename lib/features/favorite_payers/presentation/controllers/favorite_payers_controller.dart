import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/entities/favorite_payer.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/repositories/favorite_payers_repository.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/providers/favorite_payers_providers.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/domain/cpf_validator.dart';

enum FavoritePayerSaveError { duplicateCpf }

class FavoritePayersController extends AsyncNotifier<List<FavoritePayer>> {
  FavoritePayersRepository get _repo =>
      ref.read(favoritePayersRepositoryProvider);

  @override
  Future<List<FavoritePayer>> build() => _repo.getAll();

  Future<FavoritePayerSaveError?> save({
    int? id,
    required String label,
    required String cpf,
  }) async {
    final digits = CpfValidator.strip(cpf);
    if (await _repo.cpfExists(digits, excludingId: id)) {
      return FavoritePayerSaveError.duplicateCpf;
    }
    await _repo.save(FavoritePayer(id: id, label: label.trim(), cpf: digits));
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
