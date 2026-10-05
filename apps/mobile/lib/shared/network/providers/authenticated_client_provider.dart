import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/v2_providers.dart' show moozeCoreProvider;
import '../../../infra/core/mooze_api_client.dart';

/// Mooze backend client. mooze-core attaches and refreshes the session
/// token and adds the device metrics.
final moozeApiClientProvider = Provider<MoozeApiClient>((ref) {
  return MoozeApiClient(() => ref.read(moozeCoreProvider.future));
});

/// [Dio] for the Mooze backend (`BACKEND_API_URL`). Every request goes
/// through [MoozeApiClient], so existing Dio callers keep their code.
final authenticatedClientProvider = Provider<Dio>((ref) {
  return ref.watch(moozeApiClientProvider).dio();
});
