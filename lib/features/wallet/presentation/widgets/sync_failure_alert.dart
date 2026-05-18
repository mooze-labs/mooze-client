import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/app/lifecycle/liquid_availability_provider.dart';
import 'package:mooze_mobile/domain/entities/chain.dart';
import 'package:mooze_mobile/domain/entities/liquid_availability.dart';
import 'package:mooze_mobile/domain/services/service_state.dart';

/// Sync-failure indicator banner.
///
/// **Suppression contract (2026-05-18):** the banner is silent when
/// the only failure is `chain=liquid` AND [LiquidAvailability] is
/// `degraded`. That state is a "soft degrade" — Breez is operational,
/// the timeline is populating via the source-aware upsert, and
/// balances are correct. Showing alarmist red copy in that case
/// confused users into thinking the wallet was broken when it was
/// actively functional. The banner still fires for:
///
///   - Any actual sync failure (`syncState.lastError != null`).
///   - Any non-liquid chain in `errored`.
///   - Liquid errored AND [LiquidAvailability.unavailable] (no
///     fallback available).
class SyncFailureAlert extends ConsumerWidget {
  const SyncFailureAlert({super.key});

  /// Show full technical detail in debug builds; in release we show a
  /// neutral copy so users don't see Electrum URLs / stack traces.
  static const bool _showTechnicalErrorDetails = kDebugMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncAsync = ref.watch(syncStateProvider);
    final syncState = syncAsync.valueOrNull;
    if (syncState == null) return const SizedBox.shrink();

    final hasSyncError = syncState.lastError != null;
    final erroredChains = syncState.perChain.entries
        .where((e) => e.value == ServiceLifecycle.errored)
        .map((e) => e.key)
        .toList(growable: false);

    if (!hasSyncError && erroredChains.isEmpty) {
      return const SizedBox.shrink();
    }

    // Soft-degrade suppression: if the only errored chain is liquid
    // AND Breez is covering for it (degraded mode), don't alarm.
    final availability = ref.watch(liquidAvailabilityProvider).valueOrNull;
    final onlyLiquidErrored = erroredChains.length == 1 &&
        erroredChains.first == ChainId.liquid;
    if (!hasSyncError &&
        onlyLiquidErrored &&
        availability == LiquidAvailability.degraded) {
      return const SizedBox.shrink();
    }

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
                    _showTechnicalErrorDetails
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

/// Top-level wallet screen wrapper that prepends a [SyncFailureAlert]
/// banner above its [child]. Optional toggle so screens that have their
/// own sync status surface can opt out.
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
