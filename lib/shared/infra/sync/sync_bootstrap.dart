import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../lwk/providers/datasource_provider.dart';
import 'sync_service_provider.dart';
import '../bdk/providers/datasource_provider.dart';

final walletSyncBootstrapProvider = Provider<void>((ref) {
  // Start Liquid sync when datasource is ready
  ref.listen(liquidDataSourceProvider, (prev, next) {
    next.whenOrNull(
      data: (either) => either.match(
        (_) => {}, // Error case - do nothing
        (_) => ref.read(liquidSyncEffectProvider), // Success - start sync
      ),
    );
  });

  // Start BDK sync when datasource is ready
  ref.listen(bdkDatasourceProvider, (prev, next) {
    next.whenOrNull(
      data: (either) => either.match(
        (_) => {}, // Error case - do nothing
        (_) => ref.read(bdkSyncEffectProvider), // Success - start sync
      ),
    );
  });
});
