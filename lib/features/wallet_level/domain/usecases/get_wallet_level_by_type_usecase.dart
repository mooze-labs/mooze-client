import 'package:mooze_mobile/features/wallet_level/domain/entities/wallet_level_entity.dart';
import 'package:mooze_mobile/features/wallet_level/domain/repositories/wallet_levels_repository.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

/// Use Case: Get Wallet Level By Type
///
/// Retrieves a specific wallet level tier by its type.
/// Used when detailed information about a single level
/// is needed (e.g., after a level change).
class GetWalletLevelByTypeUseCase {
  final WalletLevelsRepository _repository;

  const GetWalletLevelByTypeUseCase(this._repository);

  Future<Result<WalletLevelEntity>> call(WalletLevelType type) async {
    return await _repository.getWalletLevelByType(type);
  }
}
