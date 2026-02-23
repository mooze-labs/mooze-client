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
import 'package:mooze_mobile/shared/infra/lwk/utils/liquid_electrum_fallback.dart';
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
  }) {
    debugPrint(
      '[LiquidDataSource] Created with SyncStreamController hashCode: ${syncStream.hashCode}',
    );
    debugPrint(
      '[LiquidDataSource] Network: $network, Initial electrumUrl: $electrumUrl, validateDomain: $validateDomain',
    );
  }

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
      debugPrint("[LiquidDataSource] Starting sync (Network: $network)");

      // Try sync with retry logic - increased to 4 to try all servers
      int maxAttempts = 4;
      String? lastError;
      List<Tx>? txs;
      bool syncSuccess = false;

      // IMPORTANT: Start with the URL provided to this datasource instance
      // This ensures consistency between provider creation and sync execution
      String currentUrl = electrumUrl;

      debugPrint(
        "[LiquidDataSource] Initial server from provider: $currentUrl",
      );
      debugPrint(
        "[LiquidDataSource] Fallback system server: ${LiquidElectrumFallback.getCurrentServer()}",
      );

      for (int attempt = 0; attempt < maxAttempts && !syncSuccess; attempt++) {
        // On first attempt, use the URL from constructor
        // On subsequent attempts, use fallback system
        if (attempt > 0) {
          currentUrl = LiquidElectrumFallback.getCurrentServer();
        }

        debugPrint(
          "[LiquidDataSource] Tentativa ${attempt + 1}/$maxAttempts com servidor: $currentUrl",
        );

        try {
          debugPrint(
            "[LiquidDataSource] Chamando wallet.sync_ com URL: $currentUrl, validateDomain: $validateDomain",
          );

          await wallet
              .sync_(electrumUrl: currentUrl, validateDomain: validateDomain)
              .timeout(
                const Duration(seconds: 60), // Increased from 30 to 60
                onTimeout: () {
                  throw Exception(
                    'Timeout na conexão com servidor Liquid após 60s',
                  );
                },
              );

          debugPrint(
            "[LiquidDataSource] wallet.sync_ completou, buscando transações...",
          );

          txs = await wallet.txs();
          debugPrint(
            "[LiquidDataSource] wallet.txs() retornou ${txs.length} transações",
          );

          if (txs.isEmpty) {
            debugPrint(
              "[LiquidDataSource] AVISO: Nenhuma transação encontrada na wallet Liquid",
            );
          } else {
            debugPrint(
              "[LiquidDataSource] Encontradas ${txs.length} transações Liquid",
            );
          }

          // Success!
          LiquidElectrumFallback.reportSuccess();
          syncSuccess = true;
          debugPrint(
            "[LiquidDataSource] Sync bem-sucedido com servidor: $currentUrl",
          );
        } catch (e) {
          // Extract detailed error message from LwkError
          String errorMsg;
          if (e is LwkError) {
            errorMsg = 'LwkError: ${e.msg}';
            debugPrint("[LiquidDataSource] LwkError capturado - msg: ${e.msg}");
          } else {
            errorMsg = e.toString();
            debugPrint("[LiquidDataSource] Erro tipo: ${e.runtimeType}");
          }

          lastError = errorMsg;
          debugPrint(
            "[LiquidDataSource] Tentativa ${attempt + 1} falhou: $errorMsg",
          );

          // Report failure and check if we should switch servers
          final shouldSwitch = LiquidElectrumFallback.reportFailure(errorMsg);

          if (shouldSwitch && attempt < maxAttempts - 1) {
            final newServer = LiquidElectrumFallback.switchToNextServer();
            debugPrint(
              "[LiquidDataSource] Tentando próximo servidor: $newServer",
            );
            // Wait a bit longer before switching to new server
            await Future.delayed(Duration(seconds: 2));
          } else if (attempt < maxAttempts - 1) {
            // Small delay before retry on same server
            await Future.delayed(Duration(seconds: 1));
          }
        }
      }

      if (!syncSuccess || txs == null) {
        throw Exception(
          'Falha ao sincronizar com servidores Liquid após $maxAttempts tentativas. Último erro: $lastError',
        );
      }

      final transactionEvents = await _processTransactions(txs);
      debugPrint(
        "[LiquidDataSource] Generated ${transactionEvents.length} transaction events",
      );
      debugPrint(
        "[LiquidDataSource] Using SyncStreamController hashCode: ${syncStream.hashCode}",
      );

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
    debugPrint(
      "[LiquidDataSource] _processTransactions chamado com ${txs.length} transações",
    );

    if (database == null) {
      debugPrint(
        "[LiquidDataSource] No database provided, skipping transaction processing",
      );
      return [];
    }

    if (txs.isEmpty) {
      debugPrint(
        "[LiquidDataSource] Lista de transações vazia, nada a processar",
      );
      return [];
    }

    final events = <TransactionEvent>[];
    final transactionsToSave = <TransactionsCompanion>[];

    debugPrint(
      "[LiquidDataSource] Processando ${txs.length} transações Liquid...",
    );

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
    } else {
      debugPrint(
        "[LiquidDataSource] Nenhuma transação nova ou modificada para salvar",
      );
    }

    debugPrint(
      "[LiquidDataSource] _processTransactions retornando ${events.length} eventos de ${txs.length} transações processadas",
    );

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
