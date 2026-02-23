import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../store/key_store.dart';
import '../store/key_store_impl.dart';

final keyStoreProvider = Provider<KeyStore>((ref) {
  return KeyStoreImpl();
});
