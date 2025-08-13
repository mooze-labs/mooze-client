import 'package:fpdart/fpdart.dart';

import '../../domains/repositories/blockchain_settings_repository.dart';

class BlockchainSettingsController {
  final BlockchainSettingsRepository _blockchainSettingsRepository;

  BlockchainSettingsController({
    required BlockchainSettingsRepository blockchainSettingsRepository,
  }) : _blockchainSettingsRepository = blockchainSettingsRepository;

  TaskEither<String, Unit> setNodeUrl(String url) {
    return _blockchainSettingsRepository.setNodeUrl(url);
  }

  TaskEither<String, String> getNodeUrl() {
    return _blockchainSettingsRepository.getNodeUrl();
  }
}
