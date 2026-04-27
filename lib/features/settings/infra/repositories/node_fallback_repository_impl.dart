import 'package:mooze_mobile/features/settings/domain/repositories/node_fallback_repository.dart';
import 'package:mooze_mobile/features/settings/infra/datasources/node_fallback_datasource.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

class NodeFallbackRepositoryImpl implements NodeFallbackRepository {
  final NodeFallbackDataSource _dataSource;

  const NodeFallbackRepositoryImpl(this._dataSource);

  @override
  Future<Result<bool>> getCustomFallbackEnabled() async {
    try {
      return await _dataSource.getCustomFallbackEnabled();
    } catch (e) {
      return Failure(
        'Erro ao obter a configuração de fallback: ${e.toString()}',
        e as Exception?,
      );
    }
  }

  @override
  Future<Result<void>> setCustomFallbackEnabled(bool enabled) async {
    try {
      return await _dataSource.setCustomFallbackEnabled(enabled);
    } catch (e) {
      return Failure(
        'Erro ao salvar a configuração de fallback: ${e.toString()}',
        e as Exception?,
      );
    }
  }
}
