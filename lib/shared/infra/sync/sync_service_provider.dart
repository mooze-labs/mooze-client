import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/services/providers/app_logger_provider.dart';

import 'sync_service.dart';
import '../lwk/providers/datasource_provider.dart';
import '../bdk/providers/datasource_provider.dart';

const syncDuration = 2;

final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService();
  final logger = ref.read(appLoggerProvider);
  service.setLogger(logger);

  ref.onDispose(() => service.dispose());

  return service;
});

final liquidSyncEffectProvider = FutureProvider<Either<String, Unit>>((
  ref,
) async {
  final service = ref.watch(syncServiceProvider);
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

// TODO: Add BDK sync effect provider once BDK datasource provider is implemented
final bdkSyncEffectProvider = FutureProvider<Either<String, Unit>>((ref) async {
  final service = ref.watch(syncServiceProvider);
  final dataSourceResult = await ref.watch(bdkDatasourceProvider.future);

  return dataSourceResult.fold(
    (err) => left("BDK datasource not available: $err"),
    (dataSource) =>
        service
            .startPeriodicSync(
              dataSource,
              const Duration(minutes: syncDuration),
            )
            .run(),
  );
});

final syncStateProvider = StreamProvider<SyncState>((ref) {
  final service = ref.watch(syncServiceProvider);

  return service.syncState;
});
