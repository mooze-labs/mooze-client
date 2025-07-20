import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../store/mnemonic_store_impl.dart';

import 'key_store_provider.dart';

final mnemonicProvider = FutureProvider<Option<String>>((ref) async {
  final keyStore = ref.read(keyStoreProvider);
  final mnemonicStore = MnemonicStoreImpl(keyStore: keyStore);

  final mnemonic =
      await mnemonicStore.getMnemonic().getOrElse((_) => Option.none()).run();

  return mnemonic;
});
