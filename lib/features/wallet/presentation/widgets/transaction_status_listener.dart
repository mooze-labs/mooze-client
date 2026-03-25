import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/data/models/transaction_status_event.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/transaction_monitor_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/transaction_confirmed_screen.dart';
import 'package:mooze_mobile/routes.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/infra/sync/wallet_data_manager.dart';
import 'package:mooze_mobile/shared/user/providers/user_info_provider.dart';

class TransactionStatusListener extends ConsumerStatefulWidget {
  final Widget child;

  const TransactionStatusListener({super.key, required this.child});

  @override
  ConsumerState<TransactionStatusListener> createState() =>
      _TransactionStatusListenerState();
}

class _TransactionStatusListenerState
    extends ConsumerState<TransactionStatusListener> {
  StreamSubscription<TransactionStatusEvent>? _subscription;
  final Set<String> _processedTransactions = {};
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkAndInitialize();
  }

  void _checkAndInitialize() {
    final walletStatus = ref.read(walletDataManagerProvider);

    if (walletStatus.isSuccess && !_isInitialized) {
      debugPrint(
        '[TransactionStatusListener] Wallet ready (${walletStatus.state}), starting monitoring',
      );
      _isInitialized = true;
      _setupListener();
      _startMonitoring();
    } else {
      debugPrint(
        '[TransactionStatusListener] Wallet is not ready (${walletStatus.state}), waiting...',
      );
    }
  }

  void _startMonitoring() {
    final service = ref.read(transactionMonitorServiceProvider);

    debugPrint('[TransactionStatusListener] Starting monitoring...');

    // Sync pending transactions on start
    service.syncPendingTransactions().then((_) {
      debugPrint(
        '[TransactionStatusListener] Pending transactions synchronized',
      );
    });

    // Start monitoring
    service.startMonitoring();

    debugPrint('[TransactionStatusListener] Monitoring started');
  }

  void _setupListener() {
    final service = ref.read(transactionMonitorServiceProvider);

    debugPrint('[TransactionStatusListener] Setting up event listener');

    _subscription = service.statusUpdates.listen((event) {
      debugPrint(
        '[TransactionStatusListener] Event received: ${event.transactionId}',
      );

      if (_processedTransactions.contains(event.transactionId)) {
        debugPrint(
          '[TransactionStatusListener] Event already processed, ignoring',
        );
        return;
      }

      if (mounted) {
        _processedTransactions.add(event.transactionId);

        ref.invalidate(userInfoProvider);

        debugPrint(
          '[TransactionStatusListener] Waiting 300ms before showing screen...',
        );

        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) {
            debugPrint('[TransactionStatusListener] Widget is not mounted');
            return;
          }

          final navigatorContext = rootNavigatorKey.currentContext;
          if (navigatorContext != null && mounted) {
            try {
              final asset = Asset.fromId(event.assetId);

              debugPrint(
                '[TransactionStatusListener] Showing TransactionConfirmedScreen',
              );

              TransactionConfirmedScreen.show(
                navigatorContext,
                asset: asset,
                amount: event.amount,
                transactionId: event.transactionId,
              );
            } catch (e, stack) {
              debugPrint('Error showing confirmation screen: $e');
              debugPrint('Stack: $stack');
            }
          } else {
            debugPrint('Navigator context not available');
          }
        });
      }
    });

    debugPrint('[TransactionStatusListener] Listener successfully configured');
  }

  @override
  void dispose() {
    _subscription?.cancel();
    final service = ref.read(transactionMonitorServiceProvider);
    service.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<WalletDataStatus>(walletDataManagerProvider, (previous, next) {
      if (!_isInitialized && next.isSuccess) {
        debugPrint(
          '[TransactionStatusListener] Wallet became ready (${next.state}), starting monitoring',
        );
        _isInitialized = true;
        _setupListener();
        _startMonitoring();
      }
    });

    return widget.child;
  }
}
