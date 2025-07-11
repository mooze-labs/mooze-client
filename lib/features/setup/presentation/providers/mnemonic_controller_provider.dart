import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controller/mnemonic_controller.dart';
import '../../domain/providers/mnemonic_repository_provider.dart';

final mnemonicControllerProvider = Provider<MnemonicController>((ref) {
  final repository = ref.read(mnemonicRepositoryProvider);
  return MnemonicController(repository: repository);
});
