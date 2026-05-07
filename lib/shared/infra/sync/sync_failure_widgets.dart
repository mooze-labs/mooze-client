import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/domain/services/service_state.dart';
import 'package:mooze_mobile/shared/infra/sync/sync_config.dart';

/// Widget de alerta de falha de sincronização.
///
/// Phase 2.3.3: rewritten against V2 [syncStateProvider] (the legacy
/// `hasSyncFailuresProvider` + `syncFailureDetailsProvider` lived on
/// `WalletDataManager`, now deleted). Sync is considered "failed" when
/// the orchestrator's last refresh produced a typed `SyncFailure` OR
/// any chain service is in the `errored` lifecycle.
class SyncFailureAlert extends ConsumerWidget {
  const SyncFailureAlert({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncAsync = ref.watch(syncStateProvider);
    final syncState = syncAsync.valueOrNull;
    if (syncState == null) return const SizedBox.shrink();

    final hasSyncFailures = syncState.lastError != null ||
        syncState.perChain.values
            .any((lifecycle) => lifecycle == ServiceLifecycle.errored);
    if (!hasSyncFailures) return const SizedBox.shrink();

    final failureDetails = syncState.lastError?.message;

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
          const Icon(Icons.warning, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
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
        if (showSyncAlerts) const SyncFailureAlert(),
        Expanded(child: child),
      ],
    );
  }
}
