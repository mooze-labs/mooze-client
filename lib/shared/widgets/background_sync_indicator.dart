import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/domain/entities/chain.dart';
import 'package:mooze_mobile/features/sync/domain/sync_state.dart';

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
    ref.watch(syncStateProvider);
    return child;
  }

  static bool shouldShow(SyncState? state) {
    if (state == null) return false;
    if (state.phase == SyncPhase.running) return true;
    final synced = state.firstSyncedChains;
    final missing = _operationalChains.where((c) => !synced.contains(c));
    return missing.isNotEmpty && state.phase != SyncPhase.stopped;
  }
}
