import 'dart:async';
import 'package:bdk_flutter/bdk_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
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

  bool _isSyncing = false;

  BdkDataSource({
    required this.wallet,
    required this.blockchain,
    required this.syncStream,
    required this.ref,
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
