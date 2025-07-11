import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:fpdart/fpdart.dart';

import 'key_store.dart';
import 'pin_store.dart';

class PinStoreImpl implements PinStore {
  final KeyStore _keyStore;

  PinStoreImpl({required KeyStore keyStore}) : _keyStore = keyStore;

  @override
  TaskEither<String, Unit> save(String pin) {
    if (pin.length < 4) {
      return TaskEither.left("PIN deve ter pelo menos 4 caracteres");
    }

    final salt = _generateSalt();
    final bytes = utf8.encode("$pin$salt");
    final digest = sha256.convert(bytes);

    return _keyStore
        .saveKey("pinSalt", salt)
        .andThen(() => _keyStore.saveKey("hashedPin", digest.toString()));
  }

  @override
  TaskEither<String, bool> validate(String pin) {
    return _keyStore
        .getKey("pinSalt")
        .flatMap(
          (saltOption) => saltOption.fold(
            () => TaskEither.left("Salt não encontrado."),
            (salt) => _keyStore
                .getKey("hashedPin")
                .flatMap(
                  (hashedPinOption) => hashedPinOption.fold(
                    () => TaskEither.left("PIN não configurado."),
                    (hashedPin) {
                      final bytes = utf8.encode("$pin$salt");
                      final digest = sha256.convert(bytes);
                      return TaskEither.right(digest.toString() == hashedPin);
                    },
                  ),
                ),
          ),
        );
  }

  @override
  Task<bool> hasPin() {
    return _keyStore
        .getKey("pinSalt")
        .map((saltOption) => saltOption.isSome())
        .getOrElse((l) => false);
  }

  String _generateSalt() {
    final secureRandom = SecureRandom(16);
    return base64Encode(secureRandom.bytes);
  }
}
