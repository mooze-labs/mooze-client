import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/domain/entities/chain.dart';
import 'package:mooze_mobile/features/sync/domain/sync_state.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

/// Floating "sync in progress" pill that overlays whatever child it wraps.
///
/// Mirrors the visual language of [AuthInitializerWidget] (top-right
/// rounded pill, spinner + label) so the user has a single, consistent
/// vocabulary for "something is loading in the background." Positioned
/// slightly below the auth pill so they can coexist without overlap if
/// both fire briefly.
///
/// Shows whenever a chain refresh is actively in flight
/// ([SyncPhase.running]) OR the first sync cycle has not yet completed
/// for every operational chain — that second condition catches the
/// post-cooling window where, e.g., LWK Liquid native txs are still
/// reconciling in the background after Lightning has already settled
/// and the user is on the home screen.
class BackgroundSyncIndicator extends ConsumerWidget {
  const BackgroundSyncIndicator({super.key, required this.child});

  final Widget child;

  static const _operationalChains = <ChainId>[
    ChainId.liquid,
    ChainId.bitcoin,
    ChainId.lightning,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncAsync = ref.watch(syncStateProvider);
    final state = syncAsync.valueOrNull;

    final isVisible = _shouldShow(state);

    return Stack(
      children: [
        child,
        if (isVisible)
          Positioned(
            top: 80,
            right: 10,
            child: _SyncPill(),
          ),
      ],
    );
  }

  bool _shouldShow(SyncState? state) {
    if (state == null) return false;
    if (state.phase == SyncPhase.running) return true;
    // Even after the orchestrator's `Future.wait` returned and the
    // phase flipped to `cooling`, individual chains may still be
    // streaming events into the store as the orchestrator drains its
    // persist buffer. The pill stays up until every operational chain
    // has at least one successful sync recorded.
    final synced = state.firstSyncedChains;
    final missing = _operationalChains.where((c) => !synced.contains(c));
    return missing.isNotEmpty && state.phase != SyncPhase.stopped;
  }
}

class _SyncPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context).wallet_import_msg_loading_transactions,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
