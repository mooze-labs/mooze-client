import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/key_management/providers.dart';

import '../store.dart';

final mnemonicStoreProvider = Provider<MnemonicStore>((ref) {
  final keyStore = ref.read(keyStoreProvider);
  return MnemonicStoreImpl(keyStore: keyStore);
});
