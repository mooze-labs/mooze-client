import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/providers/mnemonic_store_provider.dart';

import '../controller/mnemonic_controller.dart';

final mnemonicControllerProvider = Provider<MnemonicController>((ref) {
  final repository = ref.read(mnemonicStoreProvider);
  return MnemonicController(repository: repository);
});
