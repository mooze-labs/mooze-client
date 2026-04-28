import 'dart:async';
import 'package:bdk_flutter/bdk_flutter.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/database/database.dart';
import 'package:mooze_mobile/shared/infra/sync/sync_service.dart';
import 'package:mooze_mobile/shared/infra/sync/sync_stream_controller.dart';
import 'package:mooze_mobile/shared/infra/sync/sync_event_stream.dart';
import 'package:mooze_mobile/shared/infra/bdk/utils/electrum_fallback.dart';

const String mnemonicKey = 'mnemonic';
const String wpkhExternalDerivationPath = "m/84h/0h/0h/0";
const String wpkhInternalDerivationPath = "m/84h/1h/1h/0";

@override
class BdkDataSource implements SyncableDataSource {
  final Wallet wallet;
  final Blockchain blockchain;
  final SyncStreamController syncStream;
  final Ref ref;

  /// Optional drift database for transaction persistence. Mirrors the
  /// LiquidDataSource pattern. When non-null, every successful sync runs
  /// _processTransactions() to upsert BTC tx rows into Transactions.
  final AppDatabase? database;

  bool _isSyncing = false;

  BdkDataSource({
    required this.wallet,
    required this.blockchain,
    required this.syncStream,
    required this.ref,
    this.database,
  });

  @override
  Future<void> sync() async {
    if (_isSyncing) {
      debugPrint("[BdkDataSource] Already syncing, skipping");
      return;
    }

    _isSyncing = true;

    final syncEventController = ref.read(syncEventControllerProvider);
    debugPrint(
      "[BdkDataSource] SyncEventController hashCode: ${syncEventController.hashCode}",
    );
    debugPrint("[BdkDataSource] Emitindo started para 'bdk'");
    syncEventController.emitStarted('bdk');

    syncStream.updateProgress(
      SyncProgress(
        datasource: 'BDK',
        status: SyncStatus.syncing,
        timestamp: DateTime.now(),
      ),
    );

    try {
      debugPrint("[BdkDataSource] Starting sync");

      // Try sync with retry logic
      int maxAttempts = 3;
      String? lastError;
      bool syncSuccess = false;

      for (int attempt = 0; attempt < maxAttempts && !syncSuccess; attempt++) {
        try {
          debugPrint("[BdkDataSource] Tentativa ${attempt + 1}/$maxAttempts");

          await wallet.sync(blockchain: blockchain);

          BitcoinElectrumFallback.reportSuccess();
          syncSuccess = true;
          debugPrint("[BdkDataSource] Sync bem-sucedido");
        } catch (e) {
          lastError = e.toString();
          debugPrint(
            "[BdkDataSource] Tentativa ${attempt + 1} falhou: $lastError",
          );

          // Report failure and check if we should switch servers
          final shouldSwitch = BitcoinElectrumFallback.reportFailure(lastError);

          if (shouldSwitch && attempt < maxAttempts - 1) {
            // Switch server and invalidate blockchain provider
            final newServer = BitcoinElectrumFallback.switchToNextServer();
            debugPrint("[BdkDataSource] Servidor trocado para: $newServer");
            debugPrint(
              "[BdkDataSource] IMPORTANTE: É necessário invalidar o blockchainProvider para aplicar a mudança",
            );
          }

          // If not the last attempt, wait before retrying
          if (attempt < maxAttempts - 1) {
            await Future.delayed(Duration(seconds: 1 + attempt));
          }
        }
      }

      if (!syncSuccess) {
        throw Exception(
          'Falha ao sincronizar com servidores Bitcoin após $maxAttempts tentativas. Último erro: $lastError',
        );
      }

      // Persistence is best-effort: if it fails the user-visible sync still
      // succeeds. Next sync tick will reconcile because upsert is idempotent.
      try {
        await _processTransactions();
      } catch (e, st) {
        debugPrint('[BdkDataSource] _processTransactions failed: $e\n$st');
      }

      syncStream.updateProgress(
        SyncProgress(
          datasource: 'BDK',
          status: SyncStatus.completed,
          timestamp: DateTime.now(),
        ),
      );

      debugPrint("[BdkDataSource] Emitindo completed para 'bdk'");
      syncEventController.emitCompleted('bdk');

      debugPrint("[BdkDataSource] Sync completed");
    } catch (e, stack) {
      syncStream.updateProgress(
        SyncProgress(
          datasource: 'BDK',
          status: SyncStatus.error,
          errorMessage: e.toString(),
          timestamp: DateTime.now(),
        ),
      );

      syncEventController.emitFailed('bdk', e.toString());

      debugPrint("[BdkDataSource] Sync failed: $e\n$stack");
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  void syncInBackground() {
    sync()
        .then((_) {
          debugPrint("[BdkDataSource] Background sync completed");
        })
        .catchError((error, stackTrace) {
          debugPrint("[BdkDataSource] Background sync failed: $error");
        });
  }

  /// Reconcile the BDK wallet's known transactions with the Transactions
  /// table. Mirrors LiquidDataSource._processTransactions:
  ///   - one row per BTC tx, keyed on txid
  ///   - amount = abs(received - sent), type derived from sign of net
  ///   - insertTransactionsBatch uses InsertMode.insertOrReplace, so reorgs
  ///     and confirmation updates upsert in place rather than duplicate
  ///   - rows that disappear from the BDK view are NEVER deleted (a reorg
  ///     or temporary indexer issue could omit a tx; deletion would lose
  ///     audit data — see Phase 2 spec §5.3)
  Future<void> _processTransactions() async {
    if (database == null) {
      debugPrint(
        '[BdkDataSource] No database provided, skipping transaction processing',
      );
      return;
    }

    final rawTxs = wallet.listTransactions(includeRaw: false);
    if (rawTxs.isEmpty) {
      debugPrint('[BdkDataSource] No BTC transactions to process');
      return;
    }

    final companions = <TransactionsCompanion>[];

    for (final tx in rawTxs) {
      try {
        final received = tx.received;
        final sent = tx.sent;
        final isSend = sent > received;
        final amount = isSend ? (sent - received) : (received - sent);
        final type = isSend ? 'send' : 'receive';
        final confirmed = tx.confirmationTime != null;
        final status = confirmed ? 'confirmed' : 'pending';
        final createdAt =
            confirmed
                ? DateTime.fromMillisecondsSinceEpoch(
                  tx.confirmationTime!.timestamp.toInt() * 1000,
                )
                : DateTime.now();

        companions.add(
          TransactionsCompanion.insert(
            id: tx.txid,
            assetId: 'btc',
            amount: amount,
            type: type,
            status: status,
            createdAt: createdAt,
            confirmations: Value(confirmed ? 1 : 0),
            txHash: Value(tx.txid),
            blockchain: 'bitcoin',
          ),
        );
      } catch (e, st) {
        debugPrint(
          '[BdkDataSource] Error processing tx ${tx.txid}: $e\n$st',
        );
      }
    }

    if (companions.isNotEmpty) {
      try {
        await database!.insertTransactionsBatch(companions);
        debugPrint(
          '[BdkDataSource] Persisted ${companions.length} BTC transactions',
        );
      } catch (e, st) {
        debugPrint(
          '[BdkDataSource] insertTransactionsBatch failed: $e\n$st',
        );
      }
    }
  }
}

TaskEither<String, Wallet> setupWallet(String mnemonicStr, Network network) {
  final mnemonic = TaskEither.tryCatch(
    () async => Mnemonic.fromString(mnemonicStr),
    (err, _) => err.toString(),
  );

  final descriptor = mnemonic.flatMap(
    (m) => deriveDescriptor(m, network, wpkhExternalDerivationPath),
  );
  final changeDescriptor = mnemonic.flatMap(
    (m) => deriveDescriptor(m, network, wpkhInternalDerivationPath),
  );

  final wallet = descriptor.flatMap(
    (d) => changeDescriptor.flatMap(
      (c) => TaskEither.tryCatch(
        () async => await Wallet.create(
          descriptor: d,
          changeDescriptor: c,
          network: network,
          databaseConfig: const DatabaseConfig.memory(),
        ),
        (err, _) => err.toString(),
      ),
    ),
  );

  return wallet;
}

TaskEither<String, Descriptor> deriveDescriptor(
  Mnemonic mnemonic,
  Network network,
  String derivationPath,
) {
  final derivationPath = _derivePath(wpkhExternalDerivationPath);
  final descriptorSecretKey = _createSecretKey(network, mnemonic);

  final secretDerivationPath = derivationPath.flatMap(
    (derivationPath) => descriptorSecretKey.flatMap(
      (descSecretKey) => _deriveSecretPath(descSecretKey, derivationPath),
    ),
  );

  final externalPrivateDescriptor = secretDerivationPath.flatMap(
    (derivPath) => _createDescriptor("wpkh(${derivPath.toString()})", network),
  );

  return externalPrivateDescriptor;
}

TaskEither<String, Descriptor> _createDescriptor(
  String descriptor,
  Network network,
) => TaskEither.tryCatch(
  () async => await Descriptor.create(descriptor: descriptor, network: network),
  (err, _) => err.toString(),
);

TaskEither<String, DescriptorSecretKey> _createSecretKey(
  Network network,
  Mnemonic mnemonic,
) => TaskEither.tryCatch(
  () async =>
      await DescriptorSecretKey.create(network: network, mnemonic: mnemonic),
  (err, _) => err.toString(),
);

TaskEither<String, DescriptorSecretKey> _deriveSecretPath(
  DescriptorSecretKey key,
  DerivationPath path,
) => TaskEither.tryCatch(
  () async => key.derive(path),
  (err, _) => err.toString(),
);

TaskEither<String, DerivationPath> _derivePath(String path) =>
    TaskEither.tryCatch(
      () async => DerivationPath.create(path: path),
      (err, _) => err.toString(),
    );
