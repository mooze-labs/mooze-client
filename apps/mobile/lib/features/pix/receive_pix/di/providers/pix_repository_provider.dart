import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/features/pix/receive_pix/data/repositories/core_pix_repository.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/repositories/pix_repository.dart';

/// PIX deposits through mooze-core. The core reads the session token
/// itself, so this provider does not watch the auth providers.
final pixRepositoryProvider = Provider<PixRepository>((ref) {
  final repository = CorePixRepository(
    core: ref.watch(moozeCoreProvider.future),
  );
  ref.onDispose(repository.dispose);
  return repository;
});
