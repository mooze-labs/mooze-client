import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/core/providers/mnemonic_repository_provider.dart';

import '../controller/mnemonic_controller.dart';

final mnemonicControllerProvider = Provider<MnemonicController>((ref) {
  final repository = ref.read(mnemonicRepositoryProvider);
  return MnemonicController(repository: repository);
});
