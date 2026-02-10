import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pin_store_provider.dart';

final hasPinProvider = FutureProvider<bool>((ref) async {
  final pinStore = ref.read(pinStoreProvider);
  return await pinStore.hasPin().run();
});
