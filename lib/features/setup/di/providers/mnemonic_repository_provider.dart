import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/shared/providers/mnemonic_store_provider.dart';

import '../../domain/repositories/mnemonic_repository.dart';
import '../../data/repositories/mnemonic_repository_impl.dart';

final mnemonicRepositoryProvider = Provider<MnemonicRepository>((ref) {
  final mnemonicStore = ref.read(mnemonicStoreProvider);
  return MnemonicRepositoryImpl(mnemonicStore: mnemonicStore);
});
