import 'package:fpdart/fpdart.dart';
import 'package:flutter/foundation.dart';
import 'package:mooze_mobile/shared/storage/secure_storage.dart';

import 'key_store.dart';

class KeyStoreImpl implements KeyStore {
  @override
  TaskEither<String, Option<String>> getKey(String key) {
    if (kDebugMode) {
      debugPrint("[KeyStoreImpl] Starting getKey operation for key: $key");
    }
    final storage = SecureStorageProvider.instance;

    return TaskEither.tryCatch(
      () async {
        if (kDebugMode) {
          debugPrint(
            "[KeyStoreImpl] Attempting to read from secure storage for key: $key",
          );
        }
        final result = await storage.read(key: key);
        if (kDebugMode) {
          debugPrint(
            "[KeyStoreImpl] Secure storage read completed for key: $key, hasValue: ${result != null}",
          );
        }
        final option = Option.fromNullable(result);
        if (kDebugMode) {
          debugPrint(
            "[KeyStoreImpl] Returning option for key: $key, isSome: ${option.isSome()}",
          );
        }
        return option;
      },
      (error, stackTrace) {
        if (kDebugMode) {
          debugPrint("[KeyStoreImpl] Error reading key $key: $error");
        }
        if (kDebugMode) debugPrint("[KeyStoreImpl] Stack trace: $stackTrace");
        return "Erro ao recuperar as chaves: $error";
      },
    );
  }

  @override
  TaskEither<String, Unit> saveKey(String key, String value) {
    final storage = SecureStorageProvider.instance;

    return TaskEither.tryCatch(() async {
      await storage.write(key: key, value: value);
      return unit;
    }, (error, stackTrace) => "Erro ao salvar a frase de recuperação: $error");
  }

  @override
  TaskEither<String, Unit> deleteKey(String key) {
    if (kDebugMode) {
      debugPrint("[KeyStoreImpl] Starting deleteKey operation for key: $key");
    }
    final storage = SecureStorageProvider.instance;

    return TaskEither.tryCatch(
      () async {
        if (kDebugMode) {
          debugPrint(
            "[KeyStoreImpl] Attempting to delete from secure storage for key: $key",
          );
        }
        await storage.delete(key: key);
        if (kDebugMode) {
          debugPrint(
            "[KeyStoreImpl] Secure storage delete completed for key: $key",
          );
        }
        return unit;
      },
      (error, stackTrace) {
        if (kDebugMode) {
          debugPrint("[KeyStoreImpl] Error deleting key $key: $error");
        }
        if (kDebugMode) debugPrint("[KeyStoreImpl] Stack trace: $stackTrace");
        return "Erro ao deletar chave: $error";
      },
    );
  }
}
