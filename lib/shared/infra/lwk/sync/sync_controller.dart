import 'dart:async';
import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lwk/lwk.dart';
import 'package:mooze_mobile/shared/infra/lwk/providers/datasource_provider.dart';

import '../wallet/datasource.dart';

enum WalletSyncStatus { idle, syncing, success, error }

class WalletSyncState {
  final WalletSyncStatus status;
  final String? message;
  final DateTime? lastSync;
  final bool manual;

  const WalletSyncState({
    required this.status,
    this.message,
    this.lastSync,
    this.manual = false,
  });

  bool get isDone => status == WalletSyncStatus.success;
  bool get isSyncing => status == WalletSyncStatus.syncing;

  WalletSyncState copyWith({
    WalletSyncStatus? status,
    String? message,
    DateTime? lastSync,
    bool? manual,
  }) => WalletSyncState(
    status: status ?? this.status,
    message: message ?? this.message,
    lastSync: lastSync ?? this.lastSync,
    manual: manual ?? this.manual,
  );

  static WalletSyncState idle() =>
      const WalletSyncState(status: WalletSyncStatus.idle);
}

class WalletSyncController extends StateNotifier<WalletSyncState> {
  final Ref ref;
  final LiquidDataSource dataSource;
  ReceivePort? _receivePort;
  Completer<void>? _currentSyncCompleter;

  WalletSyncController({required this.ref, required this.dataSource})
    : super(WalletSyncState.idle());

  bool get isSyncing => state.status == WalletSyncStatus.syncing;

  Future<void> ensureSynced() async {
    if (state.isDone) return;
    if (isSyncing) {
      await _currentSyncCompleter?.future;
      return;
    }
    await startSync();
  }

  Future<void> manualSync() => startSync(manual: true);

  Future<void> startSync({bool manual = false}) async {
    if (isSyncing) {
      if (manual) {
        await _currentSyncCompleter?.future;
      }
      return;
    }

    state = state.copyWith(
      status: WalletSyncStatus.syncing,
      message: manual ? 'Manual sync started' : 'Auto sync started',
      manual: manual,
    );

    _currentSyncCompleter = Completer<void>();
    final localCompleter = _currentSyncCompleter!;

    _receivePort = ReceivePort();
    final sendPort = _receivePort!.sendPort;
    _receivePort!.listen((dynamic message) {
      if (message is _SyncSuccess) {
        state = state.copyWith(
          status: WalletSyncStatus.success,
          message: 'Synced',
          lastSync: DateTime.now(),
        );
        _currentSyncCompleter?.complete();
        _disposeIsolate();
      } else if (message is _SyncError) {
        state = state.copyWith(
          status: WalletSyncStatus.error,
          message: message.error,
        );
        _currentSyncCompleter?.completeError(message.error);
        _disposeIsolate();
      }
    });

    final args = _IsolateSyncArgs(
      sendPort: sendPort,
      electrumUrl: dataSource.electrumUrl,
      validateDomain: dataSource.validateDomain,
      network: dataSource.network,
      descriptor: dataSource.descriptor,
      dbPath: dataSource.dbPath,
    );

    try {
      await Isolate.spawn<_IsolateSyncArgs>(
        _syncIsolateEntry,
        args,
        debugName: 'wallet_sync_isolate',
        errorsAreFatal: true,
        onExit: sendPort,
      );
    } catch (e) {
      state = state.copyWith(
        status: WalletSyncStatus.error,
        message: 'Failed to spawn isolate: $e',
      );
      _currentSyncCompleter?.completeError(e);
      _disposeIsolate();
    }

    return localCompleter.future;
  }

  void _disposeIsolate() {
    _receivePort?.close();
    _receivePort = null;
    _currentSyncCompleter = null;
  }

  @override
  void dispose() {
    _disposeIsolate();
    super.dispose();
  }
}

class _SyncSuccess {}

class _SyncError {
  final String error;
  _SyncError(this.error);
}

class _IsolateSyncArgs {
  final SendPort sendPort;
  final String electrumUrl;
  final bool validateDomain;
  final Network network;
  final String descriptor;
  final String dbPath;

  _IsolateSyncArgs({
    required this.sendPort,
    required this.electrumUrl,
    required this.validateDomain,
    required this.network,
    required this.descriptor,
    required this.dbPath,
  });
}

Future<void> _syncIsolateEntry(_IsolateSyncArgs args) async {
  try {
    await LibLwk.init();
    final descriptor = Descriptor(ctDescriptor: args.descriptor);
    final wallet = await Wallet.init(
      network: args.network,
      dbpath: args.dbPath,
      descriptor: descriptor,
    );
    await wallet.sync_(
      electrumUrl: args.electrumUrl,
      validateDomain: args.validateDomain,
    );
    args.sendPort.send(_SyncSuccess());
  } catch (e) {
    args.sendPort.send(_SyncError(e.toString()));
  }
}

final walletSyncControllerProvider =
    StateNotifierProvider<WalletSyncController, WalletSyncState>((ref) {
      final dataSourceEither = ref.watch(liquidDataSourceProvider);
      return dataSourceEither.maybeWhen(
        data:
            (either) => either.match(
              (l) => WalletSyncController(
                ref: ref,
                dataSource: _NullLiquidDataSource(),
              ),
              (dataSource) =>
                  WalletSyncController(ref: ref, dataSource: dataSource),
            ),
        orElse:
            () => WalletSyncController(
              ref: ref,
              dataSource: _NullLiquidDataSource(),
            ),
      );
    });

class _NullLiquidDataSource extends LiquidDataSource {
  _NullLiquidDataSource()
    : super(
        wallet: _uninitializedWallet(),
        network: Network.testnet,
        electrumUrl: '',
        validateDomain: true,
        descriptor: '',
        dbPath: '',
      );
}

Wallet _uninitializedWallet() {
  throw Exception('Wallet not ready');
}
