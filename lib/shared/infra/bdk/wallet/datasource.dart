import 'dart:async';
import 'package:bdk_flutter/bdk_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/shared/infra/sync/sync_service.dart';
import 'package:mooze_mobile/shared/infra/sync/sync_stream_controller.dart';
import 'package:mooze_mobile/shared/infra/sync/sync_event_stream.dart';

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
      await wallet.sync(blockchain: blockchain);

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
      final errorInfo = _classifyError(e);

      debugPrint(
        "[BdkDataSource] Sync failed (${errorInfo.type}): ${errorInfo.message}",
      );

      if (kDebugMode) {
        debugPrint("[BdkDataSource] Stack trace: $stack");
      }

      syncStream.updateProgress(
        SyncProgress(
          datasource: 'BDK',
          status: SyncStatus.error,
          errorMessage: errorInfo.message,
          timestamp: DateTime.now(),
        ),
      );

      syncEventController.emitFailed('bdk', errorInfo.message);

      if (!errorInfo.isTemporary) {
        rethrow;
      }
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

  _ErrorInfo _classifyError(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    // Erros de DNS lookup
    if (errorStr.contains('failed host lookup') ||
        errorStr.contains('nodename nor servname provided') ||
        errorStr.contains('failed to lookup address')) {
      return _ErrorInfo(
        type: 'DNS Lookup',
        message: 'Erro de resolução de DNS - verifique sua conexão de internet',
        isTemporary: true,
      );
    }

    if (errorStr.contains('resource temporarily unavailable') ||
        errorStr.contains('os error 35') ||
        errorStr.contains('os error 8')) {
      return _ErrorInfo(
        type: 'Network Temporary',
        message: 'Erro temporário de rede - tentando novamente...',
        isTemporary: true,
      );
    }

    if (errorStr.contains('electrumexception')) {
      return _ErrorInfo(
        type: 'Electrum',
        message: 'Erro ao conectar com servidor Electrum',
        isTemporary: true,
      );
    }

    if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
      return _ErrorInfo(
        type: 'Timeout',
        message: 'Tempo limite excedido - conexão lenta',
        isTemporary: true,
      );
    }

    return _ErrorInfo(
      type: 'Unknown',
      message: error.toString(),
      isTemporary: false,
    );
  }
}

class _ErrorInfo {
  final String type;
  final String message;
  final bool isTemporary;

  _ErrorInfo({
    required this.type,
    required this.message,
    required this.isTemporary,
  });
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
