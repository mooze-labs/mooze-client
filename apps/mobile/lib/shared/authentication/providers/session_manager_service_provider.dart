import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/v2_providers.dart' show moozeCoreProvider;
import '../services/core_session_manager_service.dart';
import '../services/session_manager_service.dart';

/// The API session, managed by mooze-core. The core reads the mnemonic
/// from the secure store, so this provider does not watch it.
final sessionManagerServiceProvider = Provider<SessionManagerService>((ref) {
  return CoreSessionManagerService(() => ref.read(moozeCoreProvider.future));
});
