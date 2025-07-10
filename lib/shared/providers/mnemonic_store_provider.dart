import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../key_management/mnemonic_store.dart';
import '../key_management/mnemonic_store_impl.dart';

import 'key_store_provider.dart';

final mnemonicStoreProvider = Provider<MnemonicStore>((ref) {
  return MnemonicStoreImpl(keyStore: ref.read(keyStoreProvider));
});
