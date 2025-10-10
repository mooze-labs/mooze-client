import '../entities/wallet_level_entity.dart';

abstract class WalletLevelsRepository {
  Future<List<WalletLevelEntity>> getAllWalletLevels();
  Future<WalletLevelEntity> getWalletLevelByType(WalletLevelType type);
}
