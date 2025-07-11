import 'package:fpdart/fpdart.dart';
import 'package:bip39_mnemonic/bip39_mnemonic.dart';

import 'key_store.dart';
import 'mnemonic_store.dart';

const mnemonicKey = 'mnemonic_mainWallet';

class MnemonicStoreImpl implements MnemonicStore {
  final KeyStore keyStore;

  MnemonicStoreImpl({required this.keyStore});

  @override
  TaskEither<String, Unit> saveMnemonic(String mnemonic) {
    final trimmedMnemonic = mnemonic.trim();

    if (trimmedMnemonic.isEmpty) {
      return TaskEither.left("A frase de recuperação não pode ser vazia");
    }

    final splitMnemonic = trimmedMnemonic.split(' ');
    if (splitMnemonic.length != 12 && splitMnemonic.length != 24) {
      return TaskEither.left(
        "A frase de recuperação deve ter 12 ou 24 palavras",
      );
    }

    return keyStore.saveKey(mnemonicKey, trimmedMnemonic);
  }

  @override
  TaskEither<String, Option<String>> getMnemonic() {
    return keyStore.getKey(mnemonicKey);
  }

  @override
  String generateMnemonic({bool extendedPhrase = true}) {
    final int entropyLength = (extendedPhrase) ? 256 : 128;
    final mnemonic =
        Mnemonic.generate(
          Language.english,
          entropyLength: entropyLength,
        ).sentence;

    return mnemonic;
  }
}
