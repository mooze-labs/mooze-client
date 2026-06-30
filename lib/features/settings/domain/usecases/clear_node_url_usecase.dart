import 'package:mooze_mobile/features/settings/domain/repositories/blockchain_settings_repository.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

class ClearNodeUrlUseCase {
  final BlockchainSettingsRepository _repository;

  const ClearNodeUrlUseCase(this._repository);

  /// Clears the persisted custom node URL, returning the network to
  /// the system default (built-in fallback rotation).
  Future<Result<void>> call() async {
    return await _repository.clearNodeUrl();
  }
}
