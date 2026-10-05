import 'package:mooze_mobile/features/settings/domain/repositories/blockchain_settings_repository.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

class SetNodeUrlUseCase {
  final BlockchainSettingsRepository _repository;

  const SetNodeUrlUseCase(this._repository);

  /// Persists the node URL for the associated blockchain network
  Future<Result<void>> call(String url) async {
    return await _repository.setNodeUrl(url);
  }
}
