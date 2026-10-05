import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart';

import '../../domain/entities/balance.dart' as domain;
import '../../domain/entities/broadcast_result.dart' as domain;
import '../../domain/entities/chain.dart';
import '../../domain/entities/fee_estimate.dart' as domain;
import '../../domain/entities/receive_address.dart' as domain;
import '../../domain/entities/send_request.dart' as domain;
import '../../domain/entities/transaction.dart' as domain;
import '../../domain/entities/wallet_credentials.dart';
import '../../domain/events/sync_outcome.dart';
import '../../domain/events/transaction_event.dart';
import '../../domain/failures/failure.dart';
import '../../domain/services/bitcoin_wallet_service.dart';
import '../../domain/services/service_state.dart';
import '../../shared/clock/clock.dart';
import '../../shared/concurrency/mutex.dart';
import '../../shared/diagnostics/boot_tracer.dart';
import '../../shared/logging/structured_logger.dart';
import '../../shared/streams/replay_value_stream.dart';
import 'core_dto_mapper.dart';

/// Bitcoin service backed by mooze-core through flutter_rust_bridge.
///
/// Mirrors `BitcoinWalletServiceImpl`. The Rust wallet owns the BDK store,
/// the transaction cache and the change tracker. This class owns the
/// lifecycle state, the timeouts and the event stream.
///
/// NOTE(core): the BDK store lives in the core key-value store, not in the
/// `bdk-db` directory. The service does not use `WalletDirectoryGuard`.
/// NOTE(core): `sdkClient`, `sdkElectrum` and `persist()` have no bridge
/// equivalent. Legacy callers that need the raw BDK handle get nothing.
class CoreBitcoinWalletService implements BitcoinWalletService {
  /// Creates the service for an opened [core].
  CoreBitcoinWalletService({
    required MoozeCore core,
    required StructuredLogger logger,
    required Clock clock,
  }) : this.deferred(core: Future.value(core), logger: logger, clock: clock);

  /// Creates the service before the core is open. Every call awaits [core].
  /// If [core] fails, `connect` returns a [ServiceFailure].
  CoreBitcoinWalletService.deferred({
    required Future<MoozeCore> core,
    required this.logger,
    required this.clock,
  }) : _core = core {
    // Stops an unhandled-error report when the core fails before the
    // first call. Each call still sees the error when it awaits.
    _core.ignore();
  }

  final Future<MoozeCore> _core;
  final StructuredLogger logger;
  final Clock clock;

  /// Default sync budget, as in the old service.
  static const Duration defaultSyncTimeout = Duration(seconds: 60);

  final Mutex _connectMutex = Mutex();
  final Mutex _syncMutex = Mutex();

  final ReplayValueStream<ServiceState> _state =
      ReplayValueStream<ServiceState>.seeded(ServiceState.initial);
  final StreamController<TransactionEvent> _txController =
      StreamController<TransactionEvent>.broadcast();

  @override
  ChainId get chain => ChainId.bitcoin;
  @override
  Stream<ServiceState> get state => _state.stream;
  @override
  ServiceState get currentState => _state.value;
  @override
  Stream<TransactionEvent> get transactions => _txController.stream;

  @override
  Future<Either<ServiceFailure, Unit>> connect(
      WalletCredentials credentials) async {
    BootTracer.mark('bitcoin.connect.entered');
    final tEnter = clock.now();
    return _connectMutex.protect(() async {
      if (currentState.isOperational) {
        BootTracer.mark('bitcoin.connect.short_circuit');
        return const Right(unit);
      }
      _emit(ServiceLifecycle.connecting);
      try {
        final core = await _core;
        // NOTE(core): the core takes its network from `CoreConfig` at open.
        // `credentials.network` is not passed.
        await core.bitcoinConnect(mnemonic: credentials.mnemonic);
        // The core primes its tracker from the restored history, so the
        // first sync emits events only for real changes.
        _emit(ServiceLifecycle.connected, clearFailure: true);
        final totalMs = clock.now().difference(tEnter).inMilliseconds;
        BootTracer.mark('bitcoin.connected', {'total_ms': totalMs});
        logger.info('bitcoin.connected', {'total_ms': totalMs});
        return const Right(unit);
      } catch (e, st) {
        final text = e is CoreError ? coreErrorMessage(e) : '$e';
        return _fail('bdk init failed: $text', cause: e, stackTrace: st);
      }
    });
  }

  @override
  Future<Either<ServiceFailure, Unit>> disconnect() async {
    return _connectMutex.protect(() async {
      final lc = currentState.lifecycle;
      if (lc == ServiceLifecycle.disconnected ||
          lc == ServiceLifecycle.uninitialized) {
        return const Right(unit);
      }
      _emit(ServiceLifecycle.disconnecting);
      try {
        final core = await _core;
        await core.bitcoinDisconnect();
      } catch (e, st) {
        // The old service could not fail here. Log and finish the
        // transition, so a later connect starts clean.
        logger.warn('bitcoin.disconnect.core_failed', {'error': '$e'},
            error: e, stackTrace: st);
      }
      _emit(ServiceLifecycle.disconnected, clearFailure: true);
      logger.info('bitcoin.disconnected', {});
      return const Right(unit);
    });
  }

  @override
  Future<Either<ServiceFailure, SyncOutcome>> sync({Duration? timeout}) async {
    return _syncMutex.protect(() async {
      if (!currentState.isOperational) {
        return Left(ServiceFailure('not connected', chain: chain));
      }
      try {
        final core = await _core;
        // NOTE(core): a Dart timeout does not cancel the Rust sync. The
        // core keeps the wallet lock until its own I/O ends.
        final dto =
            await core.bitcoinSync().timeout(timeout ?? defaultSyncTimeout);
        await _drainEvents(core);
        _emit(ServiceLifecycle.connected,
            lastSyncAt: clock.now(), clearFailure: true);
        return Right(syncOutcomeFromDto(dto));
      } on TimeoutException catch (e, st) {
        return Left(ServiceFailure('bdk sync timeout',
            chain: chain, cause: e, stackTrace: st));
      } catch (e, st) {
        return Left(
            serviceFailureFrom(e, chain, operation: 'bdk sync', stackTrace: st));
      }
    });
  }

  @override
  Future<Either<ServiceFailure, List<domain.Transaction>>>
      listTransactions() async {
    if (!currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    return _guard('bdk listTransactions', (core) async {
      final txs = await core.bitcoinTransactions();
      return txs.map(transactionFromDto).toList(growable: false);
    });
  }

  @override
  Future<Either<ServiceFailure, int>> getBlockHeight() async {
    if (!currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    return _guard('bdk getHeight', (core) => core.bitcoinBlockHeight());
  }

  @override
  Future<Either<ServiceFailure, domain.Balance>> getBalance() async {
    if (!currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    return _guard('bdk getBalance',
        (core) async => balanceFromDto(await core.bitcoinBalance()));
  }

  // ─────────────────────────────────────────── SpendableWalletService

  @override
  Future<Either<ServiceFailure, domain.FeeEstimate>> estimateFee(
      domain.SendRequest request) async {
    if (request.chain != ChainId.bitcoin) {
      return Left(ServiceFailure(
        'bitcoin service only handles Bitcoin on-chain estimates '
        '(got: ${request.chain.name})',
        chain: chain,
      ));
    }
    if (request.assetId != null) {
      return Left(ServiceFailure(
        'bitcoin service does not handle asset sends (got assetId: '
        '${request.assetId})',
        chain: chain,
      ));
    }
    if (!currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    return _guard(
      'bdk estimateFee',
      (core) async => feeEstimateFromDto(
          await core.bitcoinEstimateFee(request: sendRequestToDto(request))),
    );
  }

  @override
  Future<Either<ServiceFailure, domain.ReceiveAddress>> nextReceiveAddress({
    String? assetId,
    String? label,
  }) async {
    if (assetId != null) {
      return Left(ServiceFailure(
        'bitcoin service does not handle asset receives (got assetId: '
        '$assetId)',
        chain: chain,
      ));
    }
    if (!currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    return _guard(
      'bdk nextReceiveAddress',
      (core) async =>
          receiveAddressFromDto(await core.bitcoinReceiveAddress(label: label)),
    );
  }

  @override
  Future<Either<ServiceFailure, domain.BroadcastResult>> sendOnchain(
      domain.SendRequest request) async {
    if (request.chain != ChainId.bitcoin) {
      return Left(ServiceFailure(
        'bitcoin service only handles Bitcoin on-chain sends '
        '(got: ${request.chain.name})',
        chain: chain,
      ));
    }
    if (request.assetId != null) {
      return Left(ServiceFailure(
        'bitcoin service does not handle asset sends (got assetId: '
        '${request.assetId})',
        chain: chain,
      ));
    }
    if (!currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    return _guard('bdk sendOnchain', (core) async {
      final dto = await core.bitcoinSend(request: sendRequestToDto(request));
      // The core queued a `created` event for the new transaction. Emit it
      // now, so the orchestrator persists the row before the UI sees it.
      await _drainEvents(core);
      return broadcastResultFromDto(dto);
    });
  }

  /// NOTE(core): the old service emitted the event synchronously. The bridge
  /// is async, so the event arrives on a later microtask.
  @override
  void registerExternalBroadcast(domain.Transaction tx) {
    if (tx.chain != ChainId.bitcoin) return;
    BootTracer.mark('bitcoin.register_external_broadcast', {
      'txid_prefix': tx.id.length > 8 ? tx.id.substring(0, 8) : tx.id,
      'amount_sat': tx.amountSat,
    });
    unawaited(_registerExternal(tx));
  }

  Future<void> _registerExternal(domain.Transaction tx) async {
    try {
      final core = await _core;
      // The core deduplicates by id and queues one `created` event.
      await core.bitcoinRegisterExternalBroadcast(
          transaction: transactionToDto(tx));
      await _drainEvents(core);
    } catch (e, st) {
      // The core rejects the call when the wallet is not connected. The
      // old service still emitted the event, so emit it from Dart.
      logger.warn('bitcoin.register_external_broadcast.core_failed',
          {'error': '$e'}, error: e, stackTrace: st);
      _emitTx(TransactionEvent(
        kind: TransactionEventKind.created,
        transaction: tx,
        observedAt: clock.now(),
      ));
    }
  }

  // ─────────────────────────────────────────── helpers

  /// Runs [body] with the core and maps every error to a [ServiceFailure].
  Future<Either<ServiceFailure, T>> _guard<T>(
    String operation,
    Future<T> Function(MoozeCore core) body,
  ) async {
    try {
      return Right(await body(await _core));
    } catch (e, st) {
      return Left(
          serviceFailureFrom(e, chain, operation: operation, stackTrace: st));
    }
  }

  /// Takes the queued transaction events from the core and emits them.
  Future<void> _drainEvents(MoozeCore core) async {
    final events = await core.bitcoinTakeEvents();
    for (final e in events) {
      _emitTx(transactionEventFromDto(e));
    }
  }

  void _emit(ServiceLifecycle l,
      {DateTime? lastSyncAt,
      ServiceFailure? failure,
      bool clearFailure = false}) {
    if (_state.isClosed) return;
    _state.add(currentState.copyWith(
      lifecycle: l,
      lastSyncAt: lastSyncAt,
      failure: failure,
      clearFailure: clearFailure,
    ));
  }

  Either<ServiceFailure, T> _fail<T>(String msg,
      {Object? cause, StackTrace? stackTrace}) {
    final f =
        ServiceFailure(msg, chain: chain, cause: cause, stackTrace: stackTrace);
    if (!_state.isClosed) {
      _state.add(currentState.copyWith(
        lifecycle: ServiceLifecycle.errored,
        failure: f,
      ));
    }
    logger.warn('bitcoin.fail', {'reason': msg});
    return Left(f);
  }

  void _emitTx(TransactionEvent e) {
    if (!_txController.isClosed) _txController.add(e);
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    if (!_txController.isClosed) await _txController.close();
    await _state.close();
  }
}
