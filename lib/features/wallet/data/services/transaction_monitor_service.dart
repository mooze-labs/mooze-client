import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/infra/sync/wallet_data_manager.dart';
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
  bool _isImporting = false;
  late DateTime _importStartTime;

  TransactionMonitorService(this._ref)
    : _storage = PendingTransactionStorage() {
    _importStartTime = DateTime.now();
  }

  Stream<TransactionStatusEvent> get statusUpdates => _statusController.stream;

  void startImporting() {
    _isImporting = true;
    _importStartTime = DateTime.now();
  }

  void finishImporting() {
    _isImporting = false;
  }

  Future<void> markExistingTransactionsAsKnown() async {
    try {
      final transactionHistoryAsync = _ref.read(transactionHistoryProvider);

      await transactionHistoryAsync.whenOrNull(
        data: (result) async {
          await result.fold((error) async {}, (transactions) async {
            for (final tx in transactions) {
              _knownTransactionIds.add(tx.id);
              if (tx.status == TransactionStatus.confirmed &&
                  (tx.type == TransactionType.receive ||
                      tx.type == TransactionType.swap)) {
                _notifiedTransactions.add(tx.id);
              }
            }
          });
        },
      );
    } catch (e) {
      // Error to mark transactions as known
    }
  }

  void startMonitoring({Duration interval = const Duration(seconds: 10)}) {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(interval, (_) => _checkTransactions());

    _checkTransactions();
  }

  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }

  Future<void> _checkTransactions() async {
    try {
      final walletStatus = _ref.read(walletDataManagerProvider);

      if (!walletStatus.isSuccess && !walletStatus.isRefreshing) {
        return;
      }

      final pendingTransactions = await _storage.getPendingTransactions();

      if (pendingTransactions.isEmpty) return;

      final transactionHistoryAsync = _ref.read(transactionHistoryProvider);

      await transactionHistoryAsync.when(
        data: (result) async {
          await result.fold(
            (error) async {
              // Error to compare transactions
            },
            (transactions) async {
              await _compareAndNotify(pendingTransactions, transactions);
            },
          );
        },
        loading: () async {},
        error: (error, stack) async {
          // debugPrint('[TransactionMonitor] Erro: $error');
        },
      );
    } catch (e) {
      // debugPrint('[TransactionMonitor] Exceção ao verificar transações: $e');
    }
  }

  Future<void> _compareAndNotify(
    List<PendingTransaction> pendingTransactions,
    List<Transaction> currentTransactions,
  ) async {
    for (final pending in pendingTransactions) {
      if (_notifiedTransactions.contains(pending.id)) {
        continue;
      }

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
        if (_isImporting) {
          _notifiedTransactions.add(pending.id);
          await _storage.removePendingTransaction(pending.id);
          continue;
        }

        _notifiedTransactions.add(pending.id);

        final isSwap =
            confirmed.type == TransactionType.swap && confirmed.toAsset != null;
        final asset = isSwap ? confirmed.toAsset! : confirmed.asset;
        final amount = isSwap ? confirmed.receivedAmount! : confirmed.amount;

        final event = TransactionStatusEvent(
          transactionId: confirmed.id,
          assetId: asset.id,
          assetTicker: asset.ticker,
          amount: amount,
          confirmedAt: DateTime.now(),
        );

        _statusController.add(event);

        await _storage.removePendingTransaction(pending.id);
      } else {
        // Transaction still pending
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
    }
  }

  Future<void> syncPendingTransactions() async {
    try {
      final walletStatus = _ref.read(walletDataManagerProvider);

      if (!walletStatus.isSuccess && !walletStatus.isRefreshing) {
        return;
      }

      final result = await _ref.read(transactionHistoryProvider.future);

      await result.fold(
        (error) async {
          // Error to sync transactions
        },
        (transactions) async {
          final oldPendingTransactions =
              await _storage.getPendingTransactions();

          if (oldPendingTransactions.isNotEmpty) {
            await _compareAndNotify(oldPendingTransactions, transactions);
          }

          await _detectNewTransactions(transactions);

          final pendingReceives = transactions.where(
            (t) =>
                t.status == TransactionStatus.pending &&
                (t.type == TransactionType.receive ||
                    t.type == TransactionType.swap),
          );

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
        },
      );
    } catch (e) {
      // debugPrint('[TransactionMonitor] Erro ao sincronizar: $e');
      // debugPrint('Stack: $stack');
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

      for (final tx in confirmedReceives) {
        final isNew = _knownTransactionIds.add(tx.id);

        if (_isImporting) {
          _notifiedTransactions.add(tx.id);
          continue;
        }

        if (tx.createdAt.isBefore(_importStartTime) ||
            tx.createdAt.isAtSameMomentAs(_importStartTime)) {
          _notifiedTransactions.add(tx.id);
          continue;
        }

        if (isNew && !_notifiedTransactions.contains(tx.id)) {
          final isSwap = tx.type == TransactionType.swap && tx.toAsset != null;
          final asset = isSwap ? tx.toAsset! : tx.asset;
          final amount = isSwap ? tx.receivedAmount! : tx.amount;

          _notifiedTransactions.add(tx.id);

          final event = TransactionStatusEvent(
            transactionId: tx.id,
            assetId: asset.id,
            assetTicker: asset.ticker,
            amount: amount,
            confirmedAt: DateTime.now(),
          );

          _statusController.add(event);
        } else if (!isNew) {
          // known transaction, no notification needed
        }
      }
    } catch (e) {
      // debugPrint('[TransactionMonitor] Erro ao detectar novas transações: $e');
      // debugPrint('Stack: $stack');
    }
  }

  Future<void> clearNotifiedTransactions() async {
    _notifiedTransactions.clear();
  }

  Future<void> clearKnownTransactions() async {
    _knownTransactionIds.clear();
  }

  void dispose() {
    _monitorTimer?.cancel();
    _statusController.close();
  }
}
