import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/settings/data/repositories/bitcoin_settings_repository_impl.dart';

import '../controller/blockchain_settings_controller.dart';

final bitcoinSettingsControllerProvider =
    Provider<BlockchainSettingsController>((ref) {
      final repo = BitcoinSettingsRepository();
      return BlockchainSettingsController(blockchainSettingsRepository: repo);
    });
