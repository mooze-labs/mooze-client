import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/sync_service.dart';

import 'datasource_provider.dart';

const syncDuration = 2;

final lwkSyncServiceProvider = Provider<LwkSyncService>((ref) {
  final service = LwkSyncService();
  ref.onDispose(() => service.stopPeriodicSync().run());

  return service;
});

final lwkSyncEffectProvider = FutureProvider<Either<String, Unit>>((ref) async {
  final service = ref.watch(lwkSyncServiceProvider);
  final dataSourceResult = await ref.watch(liquidDataSourceProvider.future);

  return dataSourceResult.fold(
    (err) => left("Liquid datasource not available: $err"),
    (dataSource) =>
        service
            .startPeriodicSync(
              dataSource,
              const Duration(minutes: syncDuration),
            )
            .run(),
  );
});

final lwkSyncStateProvider = StreamProvider<SyncState>((ref) {
  final service = ref.watch(lwkSyncServiceProvider);

  return service.syncState;
});
