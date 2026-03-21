import 'package:mooze_mobile/features/settings/domain/repositories/blockchain_settings_repository.dart';
import 'package:mooze_mobile/features/settings/infra/datasources/blockchain_settings_datasource.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

/// Blockchain Settings Repository Implementation (Infrastructure Layer)
///
/// Generic implementation that delegates to a BlockchainSettingsDataSource.
/// Used for both Bitcoin and Liquid networks by injecting the
/// appropriate data source via the DI container.
class BlockchainSettingsRepositoryImpl implements BlockchainSettingsRepository {
  final BlockchainSettingsDataSource _dataSource;

  const BlockchainSettingsRepositoryImpl(this._dataSource);

  @override
  Future<Result<void>> setNodeUrl(String url) async {
    try {
      return await _dataSource.setNodeUrl(url);
    } catch (e) {
      return Failure(
        'Erro ao atualizar a URL do node: ${e.toString()}',
        e as Exception?,
      );
    }
  }

  @override
  Future<Result<String>> getNodeUrl() async {
    try {
      return await _dataSource.getNodeUrl();
    } catch (e) {
      return Failure(
        'Erro ao obter a URL do node: ${e.toString()}',
        e as Exception?,
      );
    }
  }
}
