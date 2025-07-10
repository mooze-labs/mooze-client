import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/key_management/key_store_impl.dart';

import '../key_management/key_store.dart';

final keyStoreProvider = Provider<KeyStore>((ref) {
  return KeyStoreImpl();
});
