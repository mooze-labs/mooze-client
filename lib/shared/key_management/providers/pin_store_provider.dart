import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../store.dart';

import 'key_store_provider.dart';

final pinStoreProvider = Provider<PinStore>((ref) {
  final keyStore = ref.read(keyStoreProvider);
  return PinStoreImpl(keyStore: keyStore);
});
