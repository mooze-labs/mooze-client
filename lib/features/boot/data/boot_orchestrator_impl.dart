import 'dart:async';

import 'package:fpdart/fpdart.dart';

import '../../../domain/entities/wallet_credentials.dart';
import '../../../domain/failures/failure.dart';
import '../../../domain/repositories/secure_credential_store.dart';
import '../../../domain/repositories/transaction_store.dart';
import '../../../domain/services/bitcoin_wallet_service.dart';
import '../../../domain/services/lightning_wallet_service.dart';
import '../../../domain/services/liquid_wallet_service.dart';
import '../../../domain/services/platform_initializer.dart';
import '../../../domain/services/session_authenticator.dart';
import '../../../shared/clock/clock.dart';
import '../../../shared/concurrency/single_flight.dart';
import '../../../shared/diagnostics/boot_tracer.dart';
import '../../../shared/logging/structured_logger.dart';
import '../../../shared/streams/replay_value_stream.dart';
import '../domain/boot_orchestrator.dart';
import '../domain/boot_state.dart';

class BootOrchestratorImpl implements BootOrchestrator {
  BootOrchestratorImpl({
    required this.platformInitializer,
    required this.credentialStore,
    required this.transactionStore,
    required this.liquid,
    required this.bitcoin,
    required this.lightning,
    required this.session,
    required this.logger,
    required this.clock,
    this.connectTimeout = const Duration(seconds: 45),
    this.authTimeout = const Duration(seconds: 10),
  });

  final PlatformInitializer platformInitializer;
  final SecureCredentialStore credentialStore;
  final TransactionStore transactionStore;
  final LiquidWalletService liquid;
  final BitcoinWalletService bitcoin;
  final LightningWalletService lightning;
  final SessionAuthenticator session;
  final StructuredLogger logger;
  final Clock clock;
  final Duration connectTimeout;
  final Duration authTimeout;

  final ReplayValueStream<BootState> _state =
      ReplayValueStream<BootState>.seeded(BootState.idle);
  final SingleFlight<String, Either<BootFailure, BootState>> _flight =
      SingleFlight();

  @override
  Stream<BootState> get state => _state.stream;

  @override
  BootState get currentState => _state.value;

  @override
  Future<Either<BootFailure, BootState>> start() async {
    logger.info('boot.start.enter', {});
    final r = await _flight.run('boot.start', _runStart);
    logger.info('boot.start.exit', {'either': r.isLeft() ? 'left' : 'right'});
    return r;
  }

  Future<Either<BootFailure, BootState>> _runStart() async {
    if (currentState.isReady) {
      return Right(currentState);
    }
    final overallStart = clock.now();
    _emit(BootState(
      phase: BootPhase.initializingPlatform,
      startedAt: overallStart,
    ));

    final platformResult = await _runPhase(
      'platform',
      BootPhase.initializingPlatform,
      () async => (await platformInitializer.run()).mapLeft(
        (f) => BootFailure(f.message,
            phase: 'platform', cause: f, stackTrace: f.stackTrace),
      ),
    );
    if (platformResult.isLeft()) return _terminalLeft(platformResult);

    // ensure DB is reachable; the store impl is responsible for migrations.
    final dbResult = await _runPhase(
      'database',
      BootPhase.initializingDatabase,
      () async {
        try {
          // A read against the store is the cheapest way to force open.
          await transactionStore.list(limit: 1);
          return const Right<BootFailure, Unit>(unit);
        } catch (e, st) {
          return Left(BootFailure('database open failed: $e',
              phase: 'database', cause: e, stackTrace: st));
        }
      },
    );
    if (dbResult.isLeft()) return _terminalLeft(dbResult);

    logger.info('boot.creds.begin', {});
    final credsResult = await _runCredentialsPhase();
    logger.info('boot.creds.end', {
      'phase': currentState.phase.name,
      'either': credsResult.isLeft() ? 'left' : 'right',
    });
    if (credsResult.isLeft()) {
      // needsSetup is signalled via a special phase; do not mark error.
      if (currentState.phase == BootPhase.needsSetup) {
        logger.info('boot.needs_setup.return', {});
        _emit(currentState.copyWith(completedAt: clock.now()));
        logger.info('boot.needs_setup.emitted', {});
        return Right(currentState);
      }
      return _terminalLeft(credsResult.map((_) => unit));
    }
    final creds = credsResult.getOrElse((_) => throw StateError('unreachable'));

    final connectResult = await _runPhase(
      'connectingServices',
      BootPhase.connectingServices,
      () => _connectServices(creds),
    );
    if (connectResult.isLeft()) return _terminalLeft(connectResult);

    final authResult = await _runPhase(
      'authenticatingSession',
      BootPhase.authenticatingSession,
      () async {
        final r = await session.ensure(
          credentials: creds,
          timeout: authTimeout,
        );
        return r.fold<Either<BootFailure, Unit>>(
          (f) {
            // Auth failure is non-fatal — we proceed in degraded mode.
            logger.warn('boot.auth.degraded', {'reason': f.message});
            return const Right(unit);
          },
          (_) => const Right(unit),
        );
      },
    );
    if (authResult.isLeft()) return _terminalLeft(authResult);

    logger.info('boot.ready.emit_begin', {});
    _emit(currentState.copyWith(
      phase: BootPhase.ready,
      completedAt: clock.now(),
      clearFailure: true,
    ));
    logger.info('boot.ready.emit_end', {});
    logger.info('boot.ready', {
      'duration_ms':
          clock.now().difference(overallStart).inMilliseconds,
    });
    logger.info('boot.runstart.return_right', {});
    return Right(currentState);
  }

  Future<Either<BootFailure, WalletCredentials>>
      _runCredentialsPhase() async {
    _emit(currentState.copyWith(phase: BootPhase.loadingCredentials));
    final t0 = clock.now();
    BootTracer.mark('boot.creds.await_start');
    final loadResult = await credentialStore.load();
    final dur = clock.now().difference(t0).inMilliseconds;
    BootTracer.mark('boot.creds.await_end', {'dur_ms': dur});
    return loadResult.fold(
      (f) {
        logger.error('boot.credentials.error', {
          'duration_ms': dur,
          'reason': f.message,
        });
        final bf = BootFailure(f.message,
            phase: 'loadingCredentials',
            cause: f,
            stackTrace: f.stackTrace);
        _emit(currentState.copyWith(
          phase: BootPhase.error,
          failure: bf,
          completedAt: clock.now(),
          lastPhaseDurationMs: dur,
        ));
        return Left(bf);
      },
      (creds) {
        logger.info('boot.credentials.loaded', {
          'duration_ms': dur,
          'absent': creds.isAbsent,
        });
        if (creds.isAbsent) {
          logger.info('boot.credentials.absent.emit_begin', {});
          _emit(currentState.copyWith(
            phase: BootPhase.needsSetup,
            lastPhaseDurationMs: dur,
          ));
          logger.info('boot.credentials.absent.emit_end', {});
          return Left(BootFailure('mnemonic absent',
              phase: 'loadingCredentials'));
        }
        _emit(currentState.copyWith(lastPhaseDurationMs: dur));
        return Right(creds);
      },
    );
  }

  Future<Either<BootFailure, Unit>> _connectServices(
      WalletCredentials creds) async {
    final tStart = clock.now();
    logger.info('boot.connect.fanout_begin',
        {'timeout_ms': connectTimeout.inMilliseconds});

    Future<Either<ServiceFailure, Unit>> instrumented(
      String chain,
      Future<Either<ServiceFailure, Unit>> Function() body,
    ) async {
      final t0 = clock.now();
      try {
        final r = await body().timeout(
          connectTimeout,
          onTimeout: () {
            logger.warn('boot.connect.service_timeout', {
              'chain': chain,
              'after_ms':
                  clock.now().difference(t0).inMilliseconds,
            });
            return Left(ServiceFailure('$chain connect timeout',
                chain: liquid.chain));
          },
        );
        logger.info('boot.connect.service_done', {
          'chain': chain,
          'duration_ms':
              clock.now().difference(t0).inMilliseconds,
          'left': r.isLeft(),
        });
        return r;
      } catch (e, st) {
        logger.error('boot.connect.service_threw', {
          'chain': chain,
          'after_ms': clock.now().difference(t0).inMilliseconds,
          'error': '$e',
        }, error: e, stackTrace: st);
        rethrow;
      }
    }

    final liquidF = instrumented('liquid', () => liquid.connect(creds));
    final bitcoinF = instrumented('bitcoin', () => bitcoin.connect(creds));
    final lightningF = instrumented('lightning', () => lightning.connect(creds));

    final results = await Future.wait([liquidF, bitcoinF, lightningF]);
    logger.info('boot.connect.fanout_end', {
      'duration_ms': clock.now().difference(tStart).inMilliseconds,
    });
    final liquidR = results[0];
    final bitcoinR = results[1];
    final lightningR = results[2];

    final allFailed =
        liquidR.isLeft() && bitcoinR.isLeft() && lightningR.isLeft();
    if (allFailed) {
      final f = liquidR.swap().getOrElse(
        (_) => ServiceFailure('all services failed',
            chain: liquid.chain),
      );
      return Left(BootFailure('all chain services failed: ${f.message}',
          phase: 'connectingServices', cause: f));
    }

    // Lightning being down is a soft-degrade only when the user has no
    // lightning balance. We still consider boot successful, but log loudly.
    for (final r in results) {
      r.match((f) {
        logger.warn('boot.connect.partial', {
          'chain': f.chain.name,
          'reason': f.message,
        });
      }, (_) {});
    }
    return const Right(unit);
  }

  Future<Either<BootFailure, T>> _runPhase<T>(
    String name,
    BootPhase phase,
    Future<Either<BootFailure, T>> Function() body,
  ) async {
    _emit(currentState.copyWith(phase: phase));
    final t0 = clock.now();
    Either<BootFailure, T> result;
    try {
      result = await body();
    } catch (e, st) {
      result = Left(BootFailure('phase $name threw: $e',
          phase: name, cause: e, stackTrace: st));
    }
    final dur = clock.now().difference(t0).inMilliseconds;
    result.match(
      (f) {
        logger.error('boot.phase.failed',
            {'phase': name, 'duration_ms': dur, 'reason': f.message},
            error: f.cause, stackTrace: f.stackTrace);
        _emit(currentState.copyWith(
          phase: BootPhase.error,
          failure: f,
          completedAt: clock.now(),
          lastPhaseDurationMs: dur,
        ));
      },
      (_) {
        logger.info('boot.phase.ok', {
          'phase': name,
          'duration_ms': dur,
        });
        _emit(currentState.copyWith(lastPhaseDurationMs: dur));
      },
    );
    return result;
  }

  Either<BootFailure, BootState> _terminalLeft(Either<BootFailure, Object?> r) {
    return r.match(
      (f) => Left(f),
      (_) => Right(currentState),
    );
  }

  void _emit(BootState s) {
    if (_state.isClosed) return;
    _state.add(s);
  }

  @override
  Future<void> shutdown() async {
    logger.info('boot.shutdown.begin', {});
    // Hard ceiling per service: a stuck FFI call (lwk.Wallet.init mid-flight,
    // Breez SDK disconnect waiting on a network probe) must not block the
    // delete-and-reimport flow. The directory wipe in DeleteWalletUseCase
    // that follows is what actually deletes the wallet, so partial cleanup
    // here is acceptable. The per-service `_shuttingDown` flag (currently
    // only liquid) covers the cancellable path; this timeout covers the
    // case where the underlying call is wedged inside an FFI/native frame
    // that does not yield.
    await _safeTimed(() => lightning.disconnect(), 'lightning.disconnect',
        _lightningDisconnectCap);
    await _safeTimed(
        () => bitcoin.disconnect(), 'bitcoin.disconnect', _disconnectCap);
    await _safeTimed(
        () => liquid.disconnect(), 'liquid.disconnect', _disconnectCap);
    // Reset boot phase to idle so a subsequent `start()` actually runs.
    // `_runStart` early-returns on `currentState.isReady` — without this
    // reset, the orchestrator would still report `BootPhase.ready` from
    // the prior session after we just disconnected every service, and
    // the next `start()` (e.g., after delete + re-import) would be a
    // no-op. The user-visible symptom: home renders with no balances or
    // transactions because services never reconnect with the new
    // credentials.
    _emit(BootState.idle);
    logger.info('boot.shutdown.end', {});
  }

  static const Duration _disconnectCap = Duration(seconds: 5);

  // Breez's native disconnect routinely needs several seconds (local
  // ledger flush + Greenlight gRPC teardown). The Lightning service
  // self-bounds that call at 12 s and always returns to a clean
  // `disconnected` state (see
  // `LightningWalletServiceImpl._nativeDisconnectTimeout`). Give the
  // orchestrator a slightly larger ceiling so it does not abandon a
  // routine disconnect mid-flight — abandoning here is what previously
  // left the service's `_connectMutex` held, deadlocking the next
  // `connect()` (delete → re-import) until an app restart.
  static const Duration _lightningDisconnectCap = Duration(seconds: 15);

  Future<void> _safeTimed(
    Future<Object?> Function() fn,
    String tag,
    Duration cap,
  ) async {
    try {
      await fn().timeout(cap);
    } on TimeoutException {
      logger.warn(tag, {
        'reason':
            'disconnect did not finish in ${cap.inSeconds}s — proceeding',
      });
    } catch (e, st) {
      logger.warn(tag, {'error': '$e'}, error: e, stackTrace: st);
    }
  }

  @override
  Future<void> dispose() async {
    await shutdown();
    await _state.close();
  }
}

