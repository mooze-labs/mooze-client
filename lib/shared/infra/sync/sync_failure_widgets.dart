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

    if (!hasSyncFailures) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        border: Border.all(color: Colors.red, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Problema de Sincronização',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                if (failureDetails != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    WalletSyncConfig.showTechnicalErrorDetails
                        ? failureDetails
                        : 'O app será reiniciado automaticamente.',
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
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
    final isLoading = ref.watch(isLoadingDataProvider);

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
