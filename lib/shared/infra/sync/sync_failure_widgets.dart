import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/infra/sync/wallet_data_manager.dart';
import 'package:mooze_mobile/shared/infra/sync/sync_config.dart';

class SyncFailureAlert extends ConsumerWidget {
  const SyncFailureAlert({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSyncFailures = ref.watch(hasSyncFailuresProvider);
    final failureDetails = ref.watch(syncFailureDetailsProvider);
    final isRetrying = ref.watch(isRetryingProvider);
    final walletStatus = ref.watch(walletDataManagerProvider);

    if (!hasSyncFailures && !isRetrying) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isRetrying
                ? Colors.orange.withValues(alpha: 0.1)
                : Colors.red.withValues(alpha: 0.1),
        border: Border.all(
          color: isRetrying ? Colors.orange : Colors.red,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                isRetrying ? Icons.refresh : Icons.warning,
                color: isRetrying ? Colors.orange : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isRetrying
                      ? 'Tentando reconectar... (${walletStatus.retryCount}/${WalletSyncConfig.maxRetries})'
                      : 'Problema de Sincronização',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isRetrying ? Colors.orange : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          if (failureDetails != null && !isRetrying) ...[
            const SizedBox(height: 8),
            Text(
              WalletSyncConfig.showTechnicalErrorDetails
                  ? failureDetails
                  : 'Problema de conectividade. Tente novamente.',
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
          ],
          if (!isRetrying && walletStatus.shouldRetry) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref
                      .read(walletDataManagerProvider.notifier)
                      .initializeWallet();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Tentar Novamente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
          if (!isRetrying && !walletStatus.shouldRetry) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(walletDataManagerProvider.notifier).resetState();
                      Future.delayed(const Duration(milliseconds: 500), () {
                        ref
                            .read(walletDataManagerProvider.notifier)
                            .initializeWallet();
                      });
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reconectar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Botão "Limpar" apenas em desenvolvimento
                if (WalletSyncConfig.isDebugButtonsEnabled)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ref
                            .read(walletDataManagerProvider.notifier)
                            .resetState();
                      },
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Limpar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        side: BorderSide(color: Colors.grey[400]!),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSyncFailures = ref.watch(hasSyncFailuresProvider);
    final isRetrying = ref.watch(isRetryingProvider);
    final isLoading = ref.watch(isLoadingDataProvider);

    if (isRetrying) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Reconectando...',
            style: TextStyle(color: Colors.orange, fontSize: 12),
          ),
        ],
      );
    }

    if (hasSyncFailures) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning, color: Colors.red, size: 16),
          const SizedBox(width: 4),
          Text('Sync Error', style: TextStyle(color: Colors.red, fontSize: 12)),
        ],
      );
    }

    if (isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Sincronizando...',
            style: TextStyle(color: Colors.green, fontSize: 12),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

class WalletScreenWrapper extends ConsumerWidget {
  final Widget child;
  final bool showSyncAlerts;

  const WalletScreenWrapper({
    required this.child,
    this.showSyncAlerts = true,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        if (showSyncAlerts) SyncFailureAlert(),
        Expanded(child: child),
      ],
    );
  }
}
