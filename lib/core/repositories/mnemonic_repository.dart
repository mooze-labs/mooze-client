import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fpdart/fpdart.dart';

const String mnemonicKey = 'mnemonic_mainWallet';

abstract class MnemonicRepository {
  TaskEither<String, Option<String>> getMnemonic();
  TaskEither<String, Unit> saveMnemonic(String mnemonic);
}

class MnemonicRepositoryImpl implements MnemonicRepository {
  @override
  TaskEither<String, Option<String>> getMnemonic() {
    final FlutterSecureStorage storage = FlutterSecureStorage();

    return TaskEither.tryCatch(
      () async => Option.fromNullable(await storage.read(key: mnemonicKey)),
      (error, stackTrace) => "Erro ao recuperar a frase de recuperação: $error",
    );
  }

  @override
  TaskEither<String, Unit> saveMnemonic(String mnemonic) {
    final FlutterSecureStorage storage = FlutterSecureStorage();
    final trimmedMnemonic = mnemonic.trim();
    final splitMnemonic = trimmedMnemonic.split(' ');

    if (trimmedMnemonic.isEmpty) {
      return TaskEither.left("A frase de recuperação não pode ser vazia");
    }

    if (splitMnemonic.length != 12 && splitMnemonic.length != 24) {
      return TaskEither.left(
        "A frase de recuperação deve ter 12 ou 24 palavras",
      );
    }

    return TaskEither.tryCatch(() async {
      await storage.write(key: mnemonicKey, value: mnemonic);
      return unit;
    }, (error, stackTrace) => "Erro ao salvar a frase de recuperação: $error");
  }
}
