import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/providers/peg_operation_provider.dart';
import 'package:mooze_mobile/providers/wallet/wallet_sync_provider.dart';

/// A widget that manages app lifecycle events and handles
/// starting/stopping services appropriately
class LifecycleManager extends ConsumerStatefulWidget {
  final Widget child;

  const LifecycleManager({Key? key, required this.child}) : super(key: key);

  @override
  ConsumerState<LifecycleManager> createState() => _LifecycleManagerState();
}

class _LifecycleManagerState extends ConsumerState<LifecycleManager>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint("App lifecycle state changed to: $state");

    final syncService = ref.read(walletSyncServiceProvider.notifier);

    switch (state) {
      case AppLifecycleState.resumed:
        // App is visible and running in foreground
        syncService.startPeriodicSync();
        // Trigger an immediate sync
        syncService.syncNow();

        // Check if we have an active peg operation
        ref.refresh(activePegOperationProvider);

        break;

      case AppLifecycleState.inactive:
        // App is in an inactive state (e.g., when receiving a phone call)
        // No action needed here
        break;

      case AppLifecycleState.paused:
        // App is not visible but still running in background
        // We continue the sync timer in background
        break;

      case AppLifecycleState.detached:
        // App is detached from view hierarchy (e.g., when killed)
        syncService.stopPeriodicSync();
        break;

      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
