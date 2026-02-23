import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/shared/key_management/providers.dart';

import '../../domain/repositories/mnemonic_repository.dart';
import '../../data/repositories/mnemonic_repository_impl.dart';

final mnemonicRepositoryProvider = Provider<MnemonicRepository>((ref) {
  final mnemonicStore = ref.read(mnemonicStoreProvider);
  return MnemonicRepositoryImpl(mnemonicStore: mnemonicStore);
});
