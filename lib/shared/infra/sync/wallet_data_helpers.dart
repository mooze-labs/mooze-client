import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'wallet_data_manager.dart';

mixin WalletDataMixin {
  void ensureWalletInitialized(WidgetRef ref) {
    final walletStatus = ref.read(walletDataManagerProvider);
    if (walletStatus.state == WalletDataState.idle) {
      ref.read(walletDataManagerProvider.notifier).initializeWallet();
    }
  }

  Future<void> refreshWalletData(WidgetRef ref) async {
    final walletDataManager = ref.read(walletDataManagerProvider.notifier);
    await walletDataManager.refreshWalletData();
  }

  void invalidateWalletData(WidgetRef ref) {
    final walletDataManager = ref.read(walletDataManagerProvider.notifier);
    walletDataManager.invalidateAllWalletProviders();
  }

  bool isWalletDataLoading(WidgetRef ref) {
    return ref.watch(isLoadingDataProvider);
  }

  bool isWalletInitialLoading(WidgetRef ref) {
    final status = ref.watch(walletDataManagerProvider);
    return status.isLoading && status.isInitialLoad;
  }

  WalletDataStatus getWalletStatus(WidgetRef ref) {
    return ref.watch(walletDataManagerProvider);
  }

  void stopWalletPeriodicSync(WidgetRef ref) {
    final walletDataManager = ref.read(walletDataManagerProvider.notifier);
    walletDataManager.stopPeriodicSync();
  }
}

final walletErrorProvider = Provider<String?>((ref) {
  final walletStatus = ref.watch(walletDataManagerProvider);
  return walletStatus.hasError ? walletStatus.errorMessage : null;
});

final isWalletReadyProvider = Provider<bool>((ref) {
  final walletStatus = ref.watch(walletDataManagerProvider);
  return walletStatus.isSuccess ||
      walletStatus.state == WalletDataState.refreshing;
});

final shouldShowWalletLoadingProvider = Provider<bool>((ref) {
  final walletStatus = ref.watch(walletDataManagerProvider);
  return walletStatus.isInitialLoad ||
      (walletStatus.state == WalletDataState.loading &&
          walletStatus.lastSync == null);
});
