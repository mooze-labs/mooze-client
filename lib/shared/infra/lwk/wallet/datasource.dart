import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:lwk/lwk.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/infra/sync/sync_service.dart';
import 'package:mooze_mobile/shared/infra/sync/sync_stream_controller.dart';
import 'package:mooze_mobile/shared/infra/sync/sync_event_stream.dart';
import 'package:mooze_mobile/shared/storage/secure_storage.dart';
import 'package:mooze_mobile/database/database.dart';
import 'package:path_provider/path_provider.dart';

const String mnemonicKey = 'mnemonic';

class LiquidDataSource implements SyncableDataSource {
  final Wallet wallet;
  final Network network;
  final String electrumUrl;
  final bool validateDomain;
  final String descriptor; // original descriptor string used to init wallet
  final String dbPath; // database path used by wallet
  final SyncStreamController syncStream;
  final AppDatabase? database;
  final Ref ref;

  bool _isSyncing = false;

  LiquidDataSource({
    required this.wallet,
    required this.network,
    required this.electrumUrl,
    required this.validateDomain,
    required this.descriptor,
    required this.dbPath,
    required this.syncStream,
    required this.ref,
    this.database,
  });

  @override
  Future<void> sync() async {
    if (_isSyncing) {
      debugPrint("[LiquidDataSource] Already syncing, skipping");
      return;
    }

    _isSyncing = true;

    final syncEventController = ref.read(syncEventControllerProvider);
    debugPrint(
      "[LiquidDataSource] SyncEventController hashCode: ${syncEventController.hashCode}",
    );
    debugPrint("[LiquidDataSource] Emitindo started para 'liquid'");
    syncEventController.emitStarted('liquid');

    syncStream.updateProgress(
      SyncProgress(
        datasource: 'Liquid',
        status: SyncStatus.syncing,
        timestamp: DateTime.now(),
      ),
    );

    try {
      debugPrint("[LiquidDataSource] Starting sync");
      await wallet.sync_(
        electrumUrl: electrumUrl,
        validateDomain: validateDomain,
      );

      final txs = await wallet.txs();
      debugPrint("[LiquidDataSource] Found ${txs.length} transactions");

      final transactionEvents = await _processTransactions(txs);

      if (kDebugMode) {
        for (final tx in txs) {
          print('Transaction ID: ${tx.txid}');
        }
        print('Transaction events: ${transactionEvents.length}');
      }

      syncStream.updateProgress(
        SyncProgress(
          datasource: 'Liquid',
          status: SyncStatus.completed,
          timestamp: DateTime.now(),
          transactionEvents: transactionEvents,
        ),
      );

      debugPrint("[LiquidDataSource] Emitindo completed para 'liquid'");
      syncEventController.emitCompleted('liquid');

      debugPrint(
        "[LiquidDataSource] Sync completed with ${transactionEvents.length} events",
      );
    } catch (e, stack) {
      syncStream.updateProgress(
        SyncProgress(
          datasource: 'Liquid',
          status: SyncStatus.error,
          errorMessage: e.toString(),
          timestamp: DateTime.now(),
        ),
      );

      syncEventController.emitFailed('liquid', e.toString());

      debugPrint("[LiquidDataSource] Sync failed: $e\n$stack");
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  Future<List<TransactionEvent>> _processTransactions(List<Tx> txs) async {
    if (database == null) {
      debugPrint(
        "[LiquidDataSource] No database provided, skipping transaction processing",
      );
      return [];
    }

    final events = <TransactionEvent>[];
    final transactionsToSave = <TransactionsCompanion>[];

    for (final tx in txs) {
      try {
        final existingTx = await database!.getTransactionById(tx.txid);

        final isReceive = tx.balances.any((b) => b.value > 0);
        final type = isReceive ? 'receive' : 'send';
        final status = tx.height != null ? 'confirmed' : 'pending';
        final confirmations = tx.height != null ? 1 : 0;

        final totalAmount = tx.balances.fold<BigInt>(
          BigInt.zero,
          (sum, balance) => sum + BigInt.from(balance.value.abs()),
        );

        if (existingTx == null) {
          debugPrint("[LiquidDataSource] New transaction detected: ${tx.txid}");

          events.add(
            TransactionEvent(
              txId: tx.txid,
              eventType: TransactionEventType.newTransaction,
              blockchain: 'liquid',
              newStatus: status,
              newConfirmations: confirmations,
              timestamp: DateTime.now(),
            ),
          );

          transactionsToSave.add(
            TransactionsCompanion.insert(
              id: tx.txid,
              assetId: tx.balances.first.assetId,
              amount: totalAmount,
              type: type,
              status: status,
              createdAt:
                  tx.timestamp != null
                      ? DateTime.fromMillisecondsSinceEpoch(
                        tx.timestamp! * 1000,
                      )
                      : DateTime.now(),
              confirmations: Value(confirmations),
              txHash: Value(tx.txid),
              blockchain: 'liquid',
            ),
          );
        } else {
          var hasChanges = false;

          if (existingTx.status != status) {
            debugPrint(
              "[LiquidDataSource] Status changed for ${tx.txid}: ${existingTx.status} -> $status",
            );
            hasChanges = true;

            events.add(
              TransactionEvent(
                txId: tx.txid,
                eventType: TransactionEventType.statusChanged,
                blockchain: 'liquid',
                oldStatus: existingTx.status,
                newStatus: status,
                oldConfirmations: existingTx.confirmations,
                newConfirmations: confirmations,
                timestamp: DateTime.now(),
              ),
            );
          } else if (existingTx.confirmations != confirmations) {
            debugPrint(
              "[LiquidDataSource] Confirmations changed for ${tx.txid}: ${existingTx.confirmations} -> $confirmations",
            );
            hasChanges = true;

            events.add(
              TransactionEvent(
                txId: tx.txid,
                eventType: TransactionEventType.confirmationsChanged,
                blockchain: 'liquid',
                oldConfirmations: existingTx.confirmations,
                newConfirmations: confirmations,
                timestamp: DateTime.now(),
              ),
            );
          }

          if (hasChanges) {
            transactionsToSave.add(
              TransactionsCompanion.insert(
                id: tx.txid,
                assetId: tx.balances.first.assetId,
                amount: totalAmount,
                type: type,
                status: status,
                createdAt: existingTx.createdAt,
                confirmations: Value(confirmations),
                txHash: Value(tx.txid),
                blockchain: 'liquid',
              ),
            );
          }
        }
      } catch (e, stack) {
        debugPrint(
          "[LiquidDataSource] Error processing transaction ${tx.txid}: $e\n$stack",
        );
      }
    }

    if (transactionsToSave.isNotEmpty) {
      try {
        await database!.insertTransactionsBatch(transactionsToSave);
        debugPrint(
          "[LiquidDataSource] Saved ${transactionsToSave.length} transactions to database",
        );
      } catch (e, stack) {
        debugPrint(
          "[LiquidDataSource] Failed to save transactions: $e\n$stack",
        );
      }
    }

    return events;
  }

  void syncInBackground() {
    sync()
        .then((_) {
          debugPrint("[LiquidDataSource] Background sync completed");
        })
        .catchError((error, stackTrace) {
          debugPrint("[LiquidDataSource] Background sync failed: $error");
        });
  }

  Future<String> getAddress() async {
    final address = await wallet.addressLastUnused();
    return address.confidential;
  }

  Future<String> signPset(String pset) async {
    final mnemonic = await SecureStorageProvider.instance.read(
      key: mnemonicKey,
    );

    if (mnemonic == null) {
      throw Exception('Mnemonic not found');
    }

    final signedPset = await wallet.signedPsetWithExtraDetails(
      network: network,
      pset: pset,
      mnemonic: mnemonic,
    );

    return signedPset;
  }
}

TaskEither<String, Descriptor> deriveNewDescriptorFromMnemonic(
  String mnemonic,
  Network network,
) {
  return TaskEither.tryCatch(
    () async =>
        Descriptor.newConfidential(network: network, mnemonic: mnemonic),
    (error, stacktrace) => error.toString(),
  );
}

TaskEither<String, Wallet> initializeNewWallet(
  String descriptor,
  Network network,
) {
  final supportDir = TaskEither.tryCatch(
    () async => getApplicationSupportDirectory(),
    (error, stackTrace) => error.toString(),
  ).flatMap((dir) => TaskEither.right("${dir.path}/lwk-db"));

  final liquidDescriptor = TaskEither.fromEither(
    Either.tryCatch(
      () => Descriptor(ctDescriptor: descriptor),
      (error, stackTrace) => error.toString(),
    ),
  );

  return liquidDescriptor.flatMap(
    (desc) => supportDir.flatMap(
      (dbpath) => TaskEither.tryCatch(() async {
        return await Wallet.init(
          network: network,
          dbpath: dbpath,
          descriptor: desc,
        );
      }, (error, stackTrace) => error.toString()),
    ),
  );
}
