import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/providers/mnemonic_store_provider.dart';

final generatedMnemonicProvider = ProviderFamily<String, bool>((
  ref,
  bool extendedPhrase,
) {
  final mnemonicStore = ref.read(mnemonicStoreProvider);
  return mnemonicStore.generateMnemonic(extendedPhrase: extendedPhrase);
});
