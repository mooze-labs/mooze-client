import 'package:fpdart/fpdart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'key_store.dart';

class KeyStoreImpl implements KeyStore {
  @override
  TaskEither<String, Option<String>> getKey(String key) {
    final FlutterSecureStorage storage = FlutterSecureStorage();

    return TaskEither.tryCatch(
      () async => Option.fromNullable(await storage.read(key: key)),
      (error, stackTrace) => "Erro ao recuperar as chaves: $error",
    );
  }

  @override
  TaskEither<String, Unit> saveKey(String key, String value) {
    final FlutterSecureStorage storage = FlutterSecureStorage();

    return TaskEither.tryCatch(() async {
      await storage.write(key: key, value: value);
      return unit;
    }, (error, stackTrace) => "Erro ao salvar a frase de recuperação: $error");
  }
}
