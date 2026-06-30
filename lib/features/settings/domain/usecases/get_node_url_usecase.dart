import 'package:mooze_mobile/features/settings/domain/repositories/blockchain_settings_repository.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

class GetNodeUrlUseCase {
  final BlockchainSettingsRepository _repository;

  const GetNodeUrlUseCase(this._repository);

  /// Retrieves the stored node URL for the associated blockchain network
  Future<Result<String>> call() async {
    return await _repository.getNodeUrl();
  }
}
