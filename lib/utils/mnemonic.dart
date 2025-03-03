import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Class to interact with wallet mnemonics.
class MnemonicHandler {
  final _storage = const FlutterSecureStorage();

  Future<String> createNewBip39Mnemonic(
    String walletId,
    bool extendedPhrase,
  ) async {
    final int entropyLength = (extendedPhrase == true) ? 256 : 128;
    final mnemonic =
        Mnemonic.generate(
          Language.portuguese,
          entropyLength: entropyLength,
        ).sentence;

    await _saveMnemonic(walletId, mnemonic);
    return mnemonic;
  }

  Future<void> _saveMnemonic(String walletId, String mnemonic) async {
    await _storage.write(key: "mnemonic_$walletId", value: mnemonic);
  }

  Future<String?> retrieveWalletMnemonic(String walletId) async {
    final mnemonic = await _storage.read(key: "mnemonic_$walletId");

    return mnemonic;
  }

  Future<void> deleteMnemonic(String walletId) async {
    await _storage.delete(key: "mnemonic_$walletId");
  }
}
