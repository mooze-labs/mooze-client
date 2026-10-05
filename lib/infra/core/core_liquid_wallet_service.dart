import 'dart:async';

import 'package:flutter_rust_bridge/flutter_rust_bridge.dart' show Int64List;
import 'package:fpdart/fpdart.dart';
import 'package:mooze_core_bridge/mooze_core_bridge.dart';

import '../../domain/entities/balance.dart' as domain;
import '../../domain/entities/broadcast_result.dart' as domain;
import '../../domain/entities/chain.dart';
import '../../domain/entities/fee_estimate.dart' as domain;
import '../../domain/entities/liquid_send_draft.dart';
import '../../domain/entities/liquid_utxo.dart' as domain;
import '../../domain/entities/receive_address.dart' as domain;
import '../../domain/entities/send_request.dart' as domain;
import '../../domain/entities/transaction.dart' as domain;
import '../../domain/entities/wallet_credentials.dart';
import '../../domain/events/sync_outcome.dart';
import '../../domain/events/transaction_event.dart';
import '../../domain/failures/failure.dart';
import '../../domain/repositories/secure_credential_store.dart';
import '../../domain/services/liquid_wallet_service.dart';
import '../../domain/services/service_state.dart';
import '../../shared/clock/clock.dart';
import '../../shared/concurrency/mutex.dart';
import '../../shared/diagnostics/boot_tracer.dart';
import '../../shared/logging/structured_logger.dart';
import '../../shared/streams/replay_value_stream.dart';
import 'core_dto_mapper.dart';

/// Liquid service backed by mooze-core through flutter_rust_bridge.
///
/// Mirrors `LiquidWalletServiceImpl`. The Rust wallet owns the LWK store,
/// the transaction cache, the balance cache and the change tracker. This
/// class owns the lifecycle state, the timeouts, the event stream and the
/// mnemonic lookup for sends. The core never stores the mnemonic.
///
/// NOTE(core): the LWK store lives in the core key-value store, not in the
/// `lwk-db` directory. The service does not use `WalletDirectoryGuard`.
/// The core runs the wipe-and-retry recovery for drifted LWK state.
/// NOTE(core): Electrum endpoint rotation runs inside the core. The
/// `ElectrumEndpointResolver` and `sdkClient` have no bridge equivalent.
/// NOTE(core): the FFI tick diagnostic (`liquid.connect.ffi_tick`) is not
/// ported. The boot orchestrator timeout still bounds `connect`.
class CoreLiquidWalletService implements LiquidWalletService {
  /// Creates the service for an opened [core].
  CoreLiquidWalletService({
    required MoozeCore core,
    required StructuredLogger logger,
    required Clock clock,
    SecureCredentialStore? credentialStore,
  }) : this.deferred(
          core: Future.value(core),
          logger: logger,
          clock: clock,
          credentialStore: credentialStore,
        );

  /// Creates the service before the core is open. Every call awaits [core].
  /// If [core] fails, `connect` returns a [ServiceFailure].
  CoreLiquidWalletService.deferred({
    required Future<MoozeCore> core,
    required this.logger,
    required this.clock,
    this.credentialStore,
  }) : _core = core {
    // Stops an unhandled-error report when the core fails before the
    // first call. Each call still sees the error when it awaits.
    _core.ignore();
  }

  final Future<MoozeCore> _core;
  final StructuredLogger logger;
  final Clock clock;

  /// Source of the mnemonic for [sendOnchain]. Read once per send and never
  /// cached, which keeps V2's "no in-memory mnemonic" rule.
  final SecureCredentialStore? credentialStore;

  /// Default sync budget, as in the old service.
  static const Duration defaultSyncTimeout = Duration(seconds: 60);

  final Mutex _connectMutex = Mutex();
  final Mutex _syncMutex = Mutex();

  /// Set by `disconnect()` before it queues on `_connectMutex`. An
  /// in-flight `connect()` checks it after each await and gives up.
  bool _shuttingDown = false;

  final ReplayValueStream<ServiceState> _state =
      ReplayValueStream<ServiceState>.seeded(ServiceState.initial);
  final StreamController<TransactionEvent> _txController =
      StreamController<TransactionEvent>.broadcast();

  @override
  ChainId get chain => ChainId.liquid;
  @override
  Stream<ServiceState> get state => _state.stream;
  @override
  ServiceState get currentState => _state.value;
  @override
  Stream<TransactionEvent> get transactions => _txController.stream;

  @override
  Future<Either<ServiceFailure, Unit>> connect(
    WalletCredentials credentials,
  ) async {
    BootTracer.mark('liquid.connect.entered');
    final tEnter = clock.now();
    logger.info('liquid.connect.enter', {});
    return _connectMutex.protect(() async {
      _shuttingDown = false;
      if (currentState.isOperational) {
        logger.info('liquid.connect.short_circuit', {'reason': 'operational'});
        return const Right(unit);
      }
      _emit(ServiceLifecycle.connecting);
      try {
        final core = await _core;
        if (_shuttingDown) {
          return _fail('connect cancelled: shutdown in progress');
        }
        // NOTE(core): the core takes its network from `CoreConfig` at open.
        // `credentials.network` is not passed.
        await core.liquidConnect(mnemonic: credentials.mnemonic);
        if (_shuttingDown) {
          // The core finished while a shutdown waited. Drop the wallet.
          await core.liquidDisconnect();
          return _fail('connect cancelled: shutdown in progress');
        }
        _emit(ServiceLifecycle.connected, clearFailure: true);
        final totalMs = clock.now().difference(tEnter).inMilliseconds;
        BootTracer.mark('liquid.connected', {'total_ms': totalMs});
        logger.info('liquid.connected', {'total_ms': totalMs});
        return const Right(unit);
      } catch (e, st) {
        final text = e is CoreError ? coreErrorMessage(e) : '$e';
        logger.warn(
          'liquid.connect.threw',
          {
            'error': text,
            'errType': e.runtimeType.toString(),
            'after_ms': clock.now().difference(tEnter).inMilliseconds,
          },
          error: e,
          stackTrace: st,
        );
        // The core already prefixes its LWK errors with `lwk init failed`.
        final msg = text.startsWith('lwk init failed')
            ? text
            : 'lwk init failed: $text';
        return _fail(msg, cause: e, stackTrace: st);
      }
    });
  }

  @override
  Future<Either<ServiceFailure, Unit>> disconnect() async {
    _shuttingDown = true;
    return _connectMutex.protect(() async {
      final lc = currentState.lifecycle;
      if (lc == ServiceLifecycle.disconnected ||
          lc == ServiceLifecycle.uninitialized) {
        return const Right(unit);
      }
      _emit(ServiceLifecycle.disconnecting);
      try {
        final core = await _core;
        await core.liquidDisconnect();
        _emit(ServiceLifecycle.disconnected, clearFailure: true);
        logger.info('liquid.disconnected', {});
        return const Right(unit);
      } catch (e, st) {
        final text = e is CoreError ? coreErrorMessage(e) : '$e';
        return _fail('lwk disconnect failed: $text',
            cause: e, stackTrace: st);
      }
    });
  }

  @override
  Future<Either<ServiceFailure, SyncOutcome>> sync({Duration? timeout}) async {
    return _syncMutex.protect(() async {
      if (!currentState.isOperational) {
        return Left(ServiceFailure('not connected', chain: chain));
      }
      BootTracer.mark('liquid.sync.begin');
      try {
        final core = await _core;
        // NOTE(core): a Dart timeout does not cancel the Rust sync. The
        // core keeps the wallet lock until its own I/O ends.
        final dto =
            await core.liquidSync().timeout(timeout ?? defaultSyncTimeout);
        await _drainEvents(core);
        _emit(
          ServiceLifecycle.connected,
          lastSyncAt: clock.now(),
          clearFailure: true,
        );
        final outcome = syncOutcomeFromDto(dto);
        BootTracer.mark('liquid.sync.end', {
          'total_ms': outcome.duration.inMilliseconds,
          'fetched': outcome.fetched,
          'changed': outcome.changed,
        });
        return Right(outcome);
      } on TimeoutException catch (e, st) {
        return Left(ServiceFailure('lwk sync timeout',
            chain: chain, cause: e, stackTrace: st));
      } catch (e, st) {
        return Left(
            serviceFailureFrom(e, chain, operation: 'lwk sync', stackTrace: st));
      }
    });
  }

  @override
  Future<Either<ServiceFailure, List<domain.Transaction>>>
      listTransactions() async {
    if (!currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    return _guard('lwk listTransactions', (core) async {
      final txs = await core.liquidTransactions();
      return txs.map(transactionFromDto).toList(growable: false);
    });
  }

  @override
  Future<Either<ServiceFailure, domain.Balance>> getBalance() async {
    if (!currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    return _guard('lwk getBalance',
        (core) async => balanceFromDto(await core.liquidBalance()));
  }

  // ─────────────────────────────────────────── swap surface

  @override
  Future<Either<ServiceFailure, List<domain.LiquidUtxo>>> getUtxos() async {
    if (!currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    return _guard('lwk getUtxos', (core) async {
      final utxos = await core.liquidUtxos();
      return utxos.map(liquidUtxoFromDto).toList(growable: false);
    });
  }

  @override
  Future<Either<ServiceFailure, String>> signSwapPset({
    required String pset,
    required String mnemonic,
  }) async {
    if (!currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    return _guard('lwk signSwapPset',
        (core) => core.liquidSignSwapPset(pset: pset, mnemonic: mnemonic));
  }

  // ─────────────────────────────────────────── native Liquid send

  @override
  Future<Either<ServiceFailure, LiquidSendDraft>> buildLbtcSend({
    required String destination,
    required BigInt amountSat,
    double? feeRateSatPerVb,
    bool drain = false,
  }) async {
    if (!currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    if (!drain && amountSat <= BigInt.zero) {
      return Left(ServiceFailure('amount must be positive', chain: chain));
    }
    if (destination.trim().isEmpty) {
      return Left(ServiceFailure('destination is empty', chain: chain));
    }
    return _guard('lwk buildLbtcSend', (core) async {
      // The core runs a best-effort pre-sync, as the old service did.
      // NOTE(core): that pre-sync has no Dart timeout and does not update
      // `lastSyncAt`.
      final dto = await core.liquidBuildLbtcSend(
        destination: destination,
        amountSat: amountSat < BigInt.zero ? BigInt.zero : amountSat,
        feeRateSatPerVb: feeRateSatPerVb,
        drain: drain,
      );
      await _drainEvents(core);
      final draft = liquidSendDraftFromDto(dto);
      logger.info('liquid.build_send.ok', {
        'drain': drain,
        'amount_sat': draft.amountSat.toString(),
        'fee_sat': draft.feeSat.toString(),
        'fee_rate_sat_per_kvb': draft.feeRateSatPerKvb,
      });
      return draft;
    });
  }

  @override
  Future<Either<ServiceFailure, String>> signAndBroadcastPset({
    required String pset,
    required String mnemonic,
  }) async {
    if (!currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    if (pset.trim().isEmpty) {
      return Left(ServiceFailure('pset is empty', chain: chain));
    }
    if (mnemonic.trim().isEmpty) {
      return Left(ServiceFailure('mnemonic is empty', chain: chain));
    }
    return _guard('lwk signAndBroadcastPset', (core) async {
      final txid =
          await core.liquidSignAndBroadcast(pset: pset, mnemonic: mnemonic);
      logger.info('liquid.broadcast.ok', {'txid': txid});
      // The core ran a best-effort post-sync. Emit what it found.
      await _drainEvents(core);
      return txid;
    });
  }

  // ─────────────────────────────────────────── SpendableWalletService

  @override
  Future<Either<ServiceFailure, domain.FeeEstimate>> estimateFee(
    domain.SendRequest request,
  ) async {
    final invalid = _validateSend(request);
    if (invalid != null) return Left(invalid);
    return _guard('lwk estimateFee', (core) async {
      final dto =
          await core.liquidEstimateFee(request: sendRequestToDto(request));
      // The estimate builds a PSET after a pre-sync. Emit what it found.
      await _drainEvents(core);
      return feeEstimateFromDto(dto);
    });
  }

  @override
  Future<Either<ServiceFailure, domain.ReceiveAddress>> nextReceiveAddress({
    String? assetId,
    String? label,
  }) async {
    if (!currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    // The core formats a bare address for L-BTC and a BIP21 URI with the
    // asset id for any other asset, as the old service did.
    return _guard(
      'lwk getReceiveAddress',
      (core) async => receiveAddressFromDto(
          await core.liquidReceiveAddress(assetId: assetId, label: label)),
    );
  }

  @override
  Future<Either<ServiceFailure, domain.BroadcastResult>> sendOnchain(
    domain.SendRequest request,
  ) async {
    final store = credentialStore;
    if (store == null) {
      return Left(ServiceFailure('no credential store', chain: chain));
    }
    final invalid = _validateSend(request);
    if (invalid != null) return Left(invalid);

    // The old service loaded the mnemonic after the build. The core builds
    // first and then rejects an empty mnemonic with `mnemonic not
    // available`, so the failure order stays the same.
    final credentials = await store.load();
    final mnemonic = credentials.toNullable()?.mnemonic ?? '';

    return _guard('lwk sendOnchain', (core) async {
      final dto = await core.liquidSend(
        request: sendRequestToDto(request),
        mnemonic: mnemonic,
      );
      // The core queued the `created` event for the new transaction, plus
      // any change the pre-sync and post-sync found.
      await _drainEvents(core);
      return broadcastResultFromDto(dto);
    });
  }

  @override
  Future<Either<ServiceFailure, domain.Balance>> refreshBalance() async {
    if (!currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    return _syncMutex.protect(() async {
      final t0 = clock.now();
      final r = await _guard('lwk refreshBalance',
          (core) async => balanceFromDto(await core.liquidRefreshBalance()));
      r.match(
        (f) => logger.warn('liquid.refresh_balance.failed', {'error': f.message}),
        (b) => BootTracer.mark('liquid.refresh_balance.ok', {
          'dur_ms': clock.now().difference(t0).inMilliseconds,
          'asset_count': b.assets.length,
        }),
      );
      return r;
    });
  }

  @override
  Future<Either<ServiceFailure, domain.Balance>> applyOptimisticBalanceDelta({
    required Map<String, int> deltas,
  }) async {
    if (!currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    if (deltas.isEmpty) return getBalance();
    final ids = deltas.keys.toList(growable: false);
    final values = Int64List.fromList([for (final id in ids) deltas[id]!]);
    final r = await _guard(
      'lwk applyOptimisticBalanceDelta',
      (core) async => balanceFromDto(
          await core.liquidApplyBalanceDelta(assetIds: ids, deltas: values)),
    );
    r.match((_) {}, (b) {
      BootTracer.mark('liquid.optimistic_delta.applied', {
        'delta_count': deltas.length,
        'asset_count': b.assets.length,
      });
    });
    return r;
  }

  @override
  Future<Either<ServiceFailure, String>> getReceiveAddress() async {
    if (!currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    return _guard('lwk getReceiveAddress', (core) async {
      final r = await core.liquidReceiveAddress();
      final address = r.address;
      if (address == null || address.isEmpty) {
        throw ServiceFailure('lwk getReceiveAddress failed: empty address',
            chain: chain);
      }
      return address;
    });
  }

  // ─────────────────────────────────────────── helpers

  /// Checks a send request the way the old `_buildSend` did, before any
  /// bridge call. The DTO has no chain, so the chain check must stay here.
  ServiceFailure? _validateSend(domain.SendRequest request) {
    if (request.chain != ChainId.liquid) {
      return ServiceFailure(
        'liquid service only handles Liquid sends '
        '(got: ${request.chain.name})',
        chain: chain,
      );
    }
    if (!currentState.isOperational) {
      return ServiceFailure('not connected', chain: chain);
    }
    if (request.destination.trim().isEmpty) {
      return ServiceFailure('destination is empty', chain: chain);
    }
    return null;
  }

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
    final events = await core.liquidTakeEvents();
    for (final e in events) {
      _emitTx(transactionEventFromDto(e));
    }
  }

  void _emit(
    ServiceLifecycle l, {
    DateTime? lastSyncAt,
    ServiceFailure? failure,
    bool clearFailure = false,
  }) {
    if (_state.isClosed) return;
    _state.add(
      currentState.copyWith(
        lifecycle: l,
        lastSyncAt: lastSyncAt,
        failure: failure,
        clearFailure: clearFailure,
      ),
    );
  }

  Either<ServiceFailure, T> _fail<T>(
    String msg, {
    Object? cause,
    StackTrace? stackTrace,
  }) {
    final f =
        ServiceFailure(msg, chain: chain, cause: cause, stackTrace: stackTrace);
    if (!_state.isClosed) {
      _state.add(
        currentState.copyWith(lifecycle: ServiceLifecycle.errored, failure: f),
      );
    }
    logger.warn('liquid.fail', {'reason': msg});
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
