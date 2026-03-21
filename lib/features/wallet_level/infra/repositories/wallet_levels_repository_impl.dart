import 'package:mooze_mobile/features/wallet_level/domain/entities/wallet_level_entity.dart';
import 'package:mooze_mobile/features/wallet_level/domain/repositories/wallet_levels_repository.dart';
import 'package:mooze_mobile/features/wallet_level/infra/datasources/wallet_levels_datasource.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

/// Wallet Levels Repository Implementation (Infrastructure Layer)
///
/// Bridges the domain contract with the data source, converting
/// exceptions into typed Failure results so no exceptions leak
/// into the domain layer.
class WalletLevelsRepositoryImpl implements WalletLevelsRepository {
  final WalletLevelsDataSource _dataSource;

  const WalletLevelsRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<WalletLevelEntity>>> getAllWalletLevels() async {
    try {
      final response = await _dataSource.getWalletLevels();
      return Success(response.toEntities());
    } catch (e) {
      return Failure(
        'Erro ao buscar níveis da carteira: ${e.toString()}',
        e is Exception ? e : null,
      );
    }
  }

  @override
  Future<Result<WalletLevelEntity>> getWalletLevelByType(
    WalletLevelType type,
  ) async {
    try {
      final result = await getAllWalletLevels();
      return result.fold(
        (levels) {
          final level = levels.where((l) => l.type == type).firstOrNull;
          if (level == null) {
            return Failure('Nível ${type.name} não encontrado');
          }
          return Success(level);
        },
        (error) => Failure(error),
      );
    } catch (e) {
      return Failure(
        'Erro ao buscar nível por tipo: ${e.toString()}',
        e is Exception ? e : null,
      );
    }
  }
}
