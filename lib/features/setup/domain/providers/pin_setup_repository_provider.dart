import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/shared/providers/pin_store_provider.dart';

import '../repositories/pin_setup_repository.dart';
import '../../data/repositories/pin_setup_repository_impl.dart';

final pinSetupRepositoryProvider = Provider<PinSetupRepository>((ref) {
  final pinStore = ref.read(pinStoreProvider);
  return PinSetupRepositoryImpl(pinStore: pinStore);
});
