import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/data/models/transaction_status_event.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/transaction_monitor_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/transaction_confirmed_screen.dart';
import 'package:mooze_mobile/routes.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/infra/sync/wallet_data_manager.dart';

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
        '[TransactionStatusListener] Wallet pronto (${walletStatus.state}), iniciando monitoramento',
      );
      _isInitialized = true;
      _setupListener();
      _startMonitoring();
    } else {
      debugPrint(
        '[TransactionStatusListener] Wallet não está pronto (${walletStatus.state}), aguardando...',
      );
    }
  }

  void _startMonitoring() {
    final service = ref.read(transactionMonitorServiceProvider);

    debugPrint('[TransactionStatusListener] Iniciando monitoramento...');

    // Sync pending transactions on start
    service.syncPendingTransactions().then((_) {
      debugPrint(
        '[TransactionStatusListener] Transações pendentes sincronizadas',
      );
    });

    // Start monitoring
    service.startMonitoring();

    debugPrint('[TransactionStatusListener] Monitoramento iniciado');
  }

  void _setupListener() {
    final service = ref.read(transactionMonitorServiceProvider);

    debugPrint('[TransactionStatusListener] Configurando listener de eventos');

    _subscription = service.statusUpdates.listen((event) {
      debugPrint(
        '[TransactionStatusListener] 🎉 Evento recebido: ${event.transactionId}',
      );

      if (_processedTransactions.contains(event.transactionId)) {
        debugPrint(
          '[TransactionStatusListener] Evento já processado, ignorando',
        );
        return;
      }

      if (mounted) {
        _processedTransactions.add(event.transactionId);

        debugPrint(
          '[TransactionStatusListener] Aguardando 300ms antes de exibir tela...',
        );

        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) {
            debugPrint('[TransactionStatusListener] Widget não montado');
            return;
          }

          final navigatorContext = rootNavigatorKey.currentContext;
          if (navigatorContext != null && mounted) {
            try {
              final asset = Asset.fromId(event.assetId);

              debugPrint(
                '[TransactionStatusListener] Exibindo TransactionConfirmedScreen',
              );

              TransactionConfirmedScreen.show(
                navigatorContext,
                asset: asset,
                amount: event.amount,
                transactionId: event.transactionId,
              );
            } catch (e, stack) {
              debugPrint('Erro ao exibir tela de confirmação: $e');
              debugPrint('Stack: $stack');
            }
          } else {
            debugPrint('Navigator context não disponível');
          }
        });
      }
    });

    debugPrint('[TransactionStatusListener] Listener configurado com sucesso');
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
          '[TransactionStatusListener] Wallet ficou pronto (${next.state}), iniciando monitoramento',
        );
        _isInitialized = true;
        _setupListener();
        _startMonitoring();
      }
    });

    return widget.child;
  }
}
