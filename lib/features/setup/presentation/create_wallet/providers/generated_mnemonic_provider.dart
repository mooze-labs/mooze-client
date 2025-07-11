import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/providers/mnemonic_store_provider.dart';

// State provider to store the generated mnemonic
final currentMnemonicProvider = StateProvider<String?>((ref) => null);

// Provider to clear the stored mnemonic
final clearMnemonicProvider = Provider<void>((ref) {
  ref.read(currentMnemonicProvider.notifier).state = null;
});

// Provider to generate and store mnemonic
final generatedMnemonicProvider = ProviderFamily<String, bool>((
  ref,
  bool extendedPhrase,
) {
  final mnemonicStore = ref.read(mnemonicStoreProvider);
  final currentMnemonic = ref.read(currentMnemonicProvider);

  // If we already have a mnemonic stored, return it
  if (currentMnemonic != null) {
    return currentMnemonic;
  }

  // Generate new mnemonic and store it
  final newMnemonic = mnemonicStore.generateMnemonic(
    extendedPhrase: extendedPhrase,
  );
  ref.read(currentMnemonicProvider.notifier).state = newMnemonic;
  return newMnemonic;
});
