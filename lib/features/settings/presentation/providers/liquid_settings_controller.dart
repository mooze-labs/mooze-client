import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/settings/data/repositories/liquid_settings_repository_impl.dart';

import '../controller/blockchain_settings_controller.dart';

final liquidSettingsControllerProvider = Provider<BlockchainSettingsController>(
  (ref) {
    final repo = LiquidSettingsRepository();
    return BlockchainSettingsController(blockchainSettingsRepository: repo);
  },
);
