import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

import '../store/mnemonic_store_impl.dart';

import 'key_store_provider.dart';

final mnemonicProvider = FutureProvider<Option<String>>((ref) async {
  if (kDebugMode) debugPrint("[MnemonicProvider] Provider called, starting mnemonic read operation");
  
  final keyStore = ref.read(keyStoreProvider);
  if (kDebugMode) debugPrint("[MnemonicProvider] KeyStore obtained from provider");
  
  final mnemonicStore = MnemonicStoreImpl(keyStore: keyStore);
  if (kDebugMode) debugPrint("[MnemonicProvider] MnemonicStoreImpl created");

  if (kDebugMode) debugPrint("[MnemonicProvider] Calling mnemonicStore.getMnemonic()");
  final taskEither = mnemonicStore.getMnemonic();
  if (kDebugMode) debugPrint("[MnemonicProvider] TaskEither obtained, calling getOrElse");
  
  final eitherResult = taskEither.getOrElse((_) {
    if (kDebugMode) debugPrint("[MnemonicProvider] Error occurred, returning Option.none()");
    return Option.none();
  });
  
  if (kDebugMode) debugPrint("[MnemonicProvider] Calling run() on TaskEither");
  final mnemonic = await eitherResult.run();
  
  if (kDebugMode) debugPrint("[MnemonicProvider] Operation completed, returning mnemonic option, isSome: ${mnemonic.isSome()}");
  return mnemonic;
});
