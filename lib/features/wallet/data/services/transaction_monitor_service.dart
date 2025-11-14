import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/enums/blockchain.dart';
import '../../presentation/providers/transaction_provider.dart';
import '../models/pending_transaction.dart';
import '../models/transaction_status_event.dart';
import '../storage/pending_transaction_storage.dart';

class TransactionMonitorService {
  final Ref _ref;
  final PendingTransactionStorage _storage;
  final _statusController =
      StreamController<TransactionStatusEvent>.broadcast();

  Timer? _monitorTimer;
  final Set<String> _notifiedTransactions = {};
  final Set<String> _knownTransactionIds = {};

  TransactionMonitorService(this._ref) : _storage = PendingTransactionStorage();

  Stream<TransactionStatusEvent> get statusUpdates => _statusController.stream;

  void startMonitoring({Duration interval = const Duration(seconds: 10)}) {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(interval, (_) => _checkTransactions());

    debugPrint(
      '[TransactionMonitor] Timer iniciado com intervalo de ${interval.inSeconds}s',
    );

    // Check immediately on start
    _checkTransactions();
  }

  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }

  Future<void> _checkTransactions() async {
    try {
      final pendingTransactions = await _storage.getPendingTransactions();

      debugPrint(
        '[TransactionMonitor] Verificando ${pendingTransactions.length} transações pendentes',
      );

      if (pendingTransactions.isEmpty) return;

      final transactionHistoryAsync = _ref.read(transactionHistoryProvider);

      await transactionHistoryAsync.when(
        data: (result) async {
          await result.fold(
            (error) async {
              debugPrint(
                '[TransactionMonitor] Erro ao carregar transações: $error',
              );
            },
            (transactions) async {
              debugPrint(
                '[TransactionMonitor] Comparando com ${transactions.length} transações da API',
              );
              await _compareAndNotify(pendingTransactions, transactions);
            },
          );
        },
        loading: () async {},
        error: (error, stack) async {
          debugPrint('[TransactionMonitor] Erro: $error');
        },
      );
    } catch (e) {
      debugPrint('[TransactionMonitor] Exceção ao verificar transações: $e');
    }
  }

  Future<void> _compareAndNotify(
    List<PendingTransaction> pendingTransactions,
    List<Transaction> currentTransactions,
  ) async {
    for (final pending in pendingTransactions) {
      // Skip if already notified
      if (_notifiedTransactions.contains(pending.id)) {
        debugPrint(
          '[TransactionMonitor] Transação ${pending.id} já notificada, pulando',
        );
        continue;
      }

      debugPrint(
        '[TransactionMonitor] Verificando transação pendente: ${pending.id}',
      );

      final confirmed = currentTransactions.firstWhere(
        (t) => t.id == pending.id && t.status == TransactionStatus.confirmed,
        orElse:
            () => Transaction(
              id: '',
              amount: BigInt.zero,
              blockchain: Blockchain.bitcoin,
              asset: Asset.btc,
              type: TransactionType.unknown,
              status: TransactionStatus.pending,
              createdAt: DateTime.now(),
            ),
      );

      if (confirmed.id.isNotEmpty) {
        // Transaction confirmed!
        debugPrint(
          '[TransactionMonitor] ✅ Transação confirmada encontrada: ${pending.id}',
        );

        _notifiedTransactions.add(pending.id);

        final isSwap =
            confirmed.type == TransactionType.swap && confirmed.toAsset != null;
        final asset = isSwap ? confirmed.toAsset! : confirmed.asset;
        final amount = isSwap ? confirmed.receivedAmount! : confirmed.amount;

        debugPrint(
          '[TransactionMonitor] Tipo: ${confirmed.type.name}, Asset: ${asset.ticker}, Amount: $amount',
        );

        final event = TransactionStatusEvent(
          transactionId: confirmed.id,
          assetId: asset.id,
          assetTicker: asset.ticker,
          amount: amount,
          confirmedAt: DateTime.now(),
        );

        _statusController.add(event);

        // Remove from pending storage
        await _storage.removePendingTransaction(pending.id);

        debugPrint(
          '[TransactionMonitor] Evento disparado e transação removida do storage',
        );
      } else {
        debugPrint(
          '[TransactionMonitor] Transação ${pending.id} ainda pendente',
        );
      }
    }
  }

  Future<void> trackTransaction(Transaction transaction) async {
    if (transaction.status == TransactionStatus.pending &&
        (transaction.type == TransactionType.receive ||
            transaction.type == TransactionType.swap)) {
      final pending = PendingTransaction(
        id: transaction.id,
        assetId: transaction.asset.id,
        assetTicker: transaction.asset.ticker,
        amount: transaction.amount,
        detectedAt: DateTime.now(),
      );

      await _storage.savePendingTransaction(pending);

      debugPrint(
        '[TransactionMonitor] Rastreando transação: ${transaction.id}',
      );
    }
  }

  Future<void> syncPendingTransactions() async {
    try {
      debugPrint(
        '[TransactionMonitor] Iniciando sincronização de pendentes...',
      );

      final result = await _ref.read(transactionHistoryProvider.future);

      await result.fold(
        (error) async {
          debugPrint('[TransactionMonitor] Erro ao buscar transações: $error');
        },
        (transactions) async {
          debugPrint(
            '[TransactionMonitor] Total de transações da API: ${transactions.length}',
          );

          final oldPendingTransactions =
              await _storage.getPendingTransactions();
          debugPrint(
            '[TransactionMonitor] Transações no storage antes do sync: ${oldPendingTransactions.length}',
          );

          if (oldPendingTransactions.isNotEmpty) {
            debugPrint(
              '[TransactionMonitor] Verificando confirmações antes de atualizar storage...',
            );
            await _compareAndNotify(oldPendingTransactions, transactions);
          }

          await _detectNewTransactions(transactions);

          final pendingReceives = transactions.where(
            (t) =>
                t.status == TransactionStatus.pending &&
                (t.type == TransactionType.receive ||
                    t.type == TransactionType.swap),
          );

          debugPrint(
            '[TransactionMonitor] Transações pendentes (receive/swap): ${pendingReceives.length}',
          );

          for (final tx in pendingReceives) {
            debugPrint(
              '[TransactionMonitor] - ${tx.id}: ${tx.type.name} ${tx.asset.ticker} status=${tx.status.name}',
            );
          }

          final pendingList =
              pendingReceives
                  .map(
                    (t) => PendingTransaction(
                      id: t.id,
                      assetId: t.asset.id,
                      assetTicker: t.asset.ticker,
                      amount: t.amount,
                      detectedAt: DateTime.now(),
                    ),
                  )
                  .toList();

          await _storage.savePendingTransactions(pendingList);

          debugPrint(
            '[TransactionMonitor] ${pendingList.length} transações salvas no storage',
          );
        },
      );
    } catch (e, stack) {
      debugPrint('[TransactionMonitor] Erro ao sincronizar: $e');
      debugPrint('Stack: $stack');
    }
  }

  Future<void> _detectNewTransactions(List<Transaction> transactions) async {
    try {
      final confirmedReceives = transactions.where(
        (t) =>
            t.status == TransactionStatus.confirmed &&
            (t.type == TransactionType.receive ||
                t.type == TransactionType.swap),
      );

      debugPrint(
        '[TransactionMonitor] Verificando ${confirmedReceives.length} transações confirmadas (receive/swap)',
      );

      for (final tx in confirmedReceives) {
        final isNew = _knownTransactionIds.add(tx.id);

        if (isNew && !_notifiedTransactions.contains(tx.id)) {
          debugPrint(
            '[TransactionMonitor] 🆕 Nova transação detectada: ${tx.id}',
          );

          final isSwap = tx.type == TransactionType.swap && tx.toAsset != null;
          final asset = isSwap ? tx.toAsset! : tx.asset;
          final amount = isSwap ? tx.receivedAmount! : tx.amount;

          debugPrint(
            '[TransactionMonitor] Tipo: ${tx.type.name}, Asset: ${asset.ticker}, Amount: $amount',
          );

          _notifiedTransactions.add(tx.id);

          final event = TransactionStatusEvent(
            transactionId: tx.id,
            assetId: asset.id,
            assetTicker: asset.ticker,
            amount: amount,
            confirmedAt: DateTime.now(),
          );

          _statusController.add(event);

          debugPrint(
            '[TransactionMonitor] ✅ Evento disparado para nova transação',
          );
        } else if (!isNew) {
          debugPrint('[TransactionMonitor] Transação ${tx.id} já conhecida');
        }
      }
    } catch (e, stack) {
      debugPrint('[TransactionMonitor] Erro ao detectar novas transações: $e');
      debugPrint('Stack: $stack');
    }
  }

  Future<void> clearNotifiedTransactions() async {
    _notifiedTransactions.clear();
    debugPrint('[TransactionMonitor] Cache de notificadas limpo');
  }

  Future<void> clearKnownTransactions() async {
    _knownTransactionIds.clear();
    debugPrint('[TransactionMonitor] Cache de transações conhecidas limpo');
  }

  Future<void> debugStorageState() async {
    final pending = await _storage.getPendingTransactions();
    debugPrint('=== STORAGE DEBUG ===');
    debugPrint('Transações pendentes no storage: ${pending.length}');
    for (final tx in pending) {
      debugPrint('  - ${tx.id}: ${tx.assetTicker} ${tx.amount}');
    }
    debugPrint('Transações notificadas: ${_notifiedTransactions.length}');
    for (final id in _notifiedTransactions) {
      debugPrint('  - $id');
    }
    debugPrint('Transações conhecidas: ${_knownTransactionIds.length}');
    debugPrint('====================');
  }

  void dispose() {
    _monitorTimer?.cancel();
    _statusController.close();
  }
}
