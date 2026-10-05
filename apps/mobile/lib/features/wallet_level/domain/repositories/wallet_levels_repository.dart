import 'package:mooze_mobile/shared/utils/result.dart';

import '../entities/wallet_level_entity.dart';

abstract class WalletLevelsRepository {
  /// Retrieves all available wallet levels with their limits
  Future<Result<List<WalletLevelEntity>>> getAllWalletLevels();

  /// Retrieves a specific wallet level by its type
  Future<Result<WalletLevelEntity>> getWalletLevelByType(WalletLevelType type);
}
