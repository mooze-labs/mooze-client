import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../key_management/pin_store.dart';
import '../key_management/pin_store_impl.dart';

import 'key_store_provider.dart';

final pinStoreProvider = Provider<PinStore>((ref) {
  return PinStoreImpl(keyStore: ref.read(keyStoreProvider));
});
