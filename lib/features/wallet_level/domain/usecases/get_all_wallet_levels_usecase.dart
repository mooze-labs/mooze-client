import 'package:mooze_mobile/features/wallet_level/domain/entities/wallet_level_entity.dart';
import 'package:mooze_mobile/features/wallet_level/domain/repositories/wallet_levels_repository.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

/// Use Case: Get All Wallet Levels
///
/// Retrieves all available wallet level tiers with their
/// respective limits. Used in the wallet levels screen to
/// display the full tier progression.
class GetAllWalletLevelsUseCase {
  final WalletLevelsRepository _repository;

  const GetAllWalletLevelsUseCase(this._repository);

  Future<Result<List<WalletLevelEntity>>> call() async {
    return await _repository.getAllWalletLevels();
  }
}
