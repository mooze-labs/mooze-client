import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/entities/favorite_payer.dart';
import 'package:mooze_mobile/features/favorite_payers/domain/repositories/favorite_payers_repository.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/controllers/own_payer_controller.dart';
import 'package:mooze_mobile/features/favorite_payers/presentation/providers/favorite_payers_providers.dart';
import 'package:mooze_mobile/features/pix/shared/cpf/domain/cpf_validator.dart';

export 'package:mooze_mobile/features/favorite_payers/domain/repositories/favorite_payers_repository.dart'
    show FavoritePayerSaveError;

class FavoritePayersController extends AsyncNotifier<List<FavoritePayer>> {
  FavoritePayersRepository get _repo =>
      ref.read(favoritePayersRepositoryProvider);

  @override
  Future<List<FavoritePayer>> build() => _repo.getAll();

  /// Saves a payer. The core strips the CPF mask, trims the label and
  /// refuses a CPF that another payer has.
  ///
  /// With [markAsOwn], the saved payer becomes "my user". The core does not
  /// return the id of a new payer, so the payer is found by its document,
  /// which no other payer can have.
  Future<FavoritePayerSaveError?> save({
    int? id,
    required String label,
    required String cpf,
    bool markAsOwn = false,
  }) async {
    final error =
        await _repo.save(FavoritePayer(id: id, label: label, cpf: cpf));
    if (error != null) return error;
    final payers = await _repo.getAll();
    state = AsyncData(payers);
    if (markAsOwn) {
      final digits = CpfValidator.strip(cpf);
      final savedId = payers.where((p) => p.cpf == digits).firstOrNull?.id;
      if (savedId != null) {
        await ref.read(ownPayerIdProvider.notifier).mark(savedId);
      }
    }
    return null;
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    // A payer saved later can get the same id. The mark must not pass to it.
    if (ref.read(ownPayerIdProvider) == id) {
      await ref.read(ownPayerIdProvider.notifier).unmark();
    }
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
