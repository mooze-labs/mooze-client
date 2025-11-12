import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/infra/sync/wallet_data_manager.dart';
import 'package:mooze_mobile/shared/infra/sync/sync_config.dart';

class HotReloadResetListener extends ConsumerWidget {
  final Widget child;

  const HotReloadResetListener({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (WalletSyncConfig.isHotReloadDetectionEnabled) {
      ref.listen(walletDataManagerProvider, (prev, next) {
        if (prev != null &&
            (prev.hasError || prev.isRetrying) &&
            next.state == WalletDataState.idle) {
          WalletSyncLogger.debug(
            '[HotReloadResetListener] Hot reload detectado - resetando flags de erro',
          );
        }
      });
    }

    return child;
  }
}

final hotReloadDetectorProvider = Provider<void>((ref) {
  if (!WalletSyncConfig.isAutoResetEnabled) {
    return;
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final walletStatus = ref.read(walletDataManagerProvider);

    if (walletStatus.hasError ||
        walletStatus.isRetrying ||
        walletStatus.hasLiquidSyncFailed ||
        walletStatus.hasBdkSyncFailed) {
      WalletSyncLogger.debug(
        '[HotReloadDetector] Resetando estado após hot reload...',
      );
      ref.read(walletDataManagerProvider.notifier).resetState();

      Future.delayed(const Duration(milliseconds: 500), () {
        if (ref.read(walletDataManagerProvider).state == WalletDataState.idle) {
          ref.read(walletDataManagerProvider.notifier).initializeWallet();
        }
      });
    }
  });
});
