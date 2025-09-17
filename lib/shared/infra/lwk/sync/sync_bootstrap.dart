import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/datasource_provider.dart';
import 'sync_controller.dart';

final walletSyncBootstrapProvider = Provider<void>((ref) {
  ref.listen(liquidDataSourceProvider, (prev, next) {
    next.whenOrNull(
      data:
          (either) => either.match((_) {}, (_) {
            final controller = ref.read(walletSyncControllerProvider.notifier);
            controller.startSync();
          }),
    );
  });
});
