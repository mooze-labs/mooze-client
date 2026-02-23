import '../../domain/entities/wallet_level_entity.dart';
import '../../domain/repositories/wallet_levels_repository.dart';
import '../datasources/wallet_levels_data_source.dart';

class WalletLevelsRepositoryImpl implements WalletLevelsRepository {
  final WalletLevelsDataSource dataSource;

  WalletLevelsRepositoryImpl({required this.dataSource});

  @override
  Future<List<WalletLevelEntity>> getAllWalletLevels() async {
    try {
      final response = await dataSource.getWalletLevels();
      return response.toEntities();
    } catch (e) {
      throw Exception('Failed to get wallet levels: $e');
    }
  }

  @override
  Future<WalletLevelEntity> getWalletLevelByType(WalletLevelType type) async {
    try {
      final levels = await getAllWalletLevels();
      final level = levels.firstWhere(
        (level) => level.type == type,
        orElse: () => throw Exception('Wallet level not found for type: $type'),
      );
      return level;
    } catch (e) {
      throw Exception('Failed to get wallet level by type: $e');
    }
  }
}
