import 'dart:async';

import 'package:fpdart/fpdart.dart';

import '../../domain/failures/failure.dart';
import '../../features/boot/domain/boot_orchestrator.dart';
import '../../features/boot/domain/boot_state.dart';
import '../../features/sync/domain/sync_orchestrator.dart';
import '../../features/wallet/domain/usecases/delete_wallet.dart';
import '../../shared/clock/clock.dart';
import '../../shared/concurrency/single_flight.dart';
import '../../shared/diagnostics/boot_tracer.dart';
import '../../shared/logging/structured_logger.dart';
import '../../shared/streams/replay_value_stream.dart';
import 'app_lifecycle_controller.dart';
import 'app_state.dart';

class AppLifecycleControllerImpl implements AppLifecycleController {
  AppLifecycleControllerImpl({
    required this.boot,
    required this.sync,
    required this.deleteWallet,
    required this.logger,
    required this.clock,
  });

  final BootOrchestrator boot;
  final SyncOrchestrator sync;
  final DeleteWalletUseCase deleteWallet;
  final StructuredLogger logger;
  final Clock clock;

  final ReplayValueStream<AppState> _state =
      ReplayValueStream<AppState>.seeded(AppState.uninitialized);
  final SingleFlight<String, Either<Failure, AppState>> _flight =
      SingleFlight();

  @override
  Stream<AppState> get state => _state.stream;
  @override
  AppState get currentState => _state.value;

  @override
  Future<Either<Failure, AppState>> start() {
    return _flight.run('start', _runStart);
  }

  Future<Either<Failure, AppState>> _runStart() async {
    if (currentState.phase == AppPhase.ready) return Right(currentState);

    _emit(currentState.copyWith(
      phase: AppPhase.booting,
      startedAt: clock.now(),
      clearFailure: true,
    ));

    logger.info('app.start.boot_begin', {});
    BootTracer.mark('lifecycle.boot.start');
    final r = await boot.start();
    BootTracer.mark('lifecycle.boot.end', {
      'phase': boot.currentState.phase.name,
      'either': r.isLeft() ? 'left' : 'right',
    });
    logger.info('app.start.boot_end', {
      'boot_phase': boot.currentState.phase.name,
      'either': r.isLeft() ? 'left' : 'right',
    });

    // needsSetup is a non-error terminal phase that boot signals via either
    // Right(currentState) or Left(BootFailure) depending on path. We branch
    // on the orchestrator's actual phase, not the Either side.
    if (boot.currentState.phase == BootPhase.needsSetup) {
      logger.info('app.start.needs_setup', {});
      _emit(currentState.copyWith(phase: AppPhase.needsSetup));
      return Right(currentState);
    }

    if (r.isLeft()) {
      final f = r.swap().getOrElse(
            (_) => const BootFailure('unknown', phase: 'unknown'),
          );
      logger.error('app.start.boot_failed', {'reason': f.message});
      _emit(currentState.copyWith(phase: AppPhase.error, failure: f));
      return Left(f);
    }

    // Boot succeeded → emit ready immediately and kick sync off in the
    // background (progressive hydration). Previously this awaited
    // `sync.start()`, which itself awaits the first `refresh()` before
    // constructing the periodic timer — so `AppPhase.ready` was gated on
    // a full first-sync cycle. With three chains synced sequentially that
    // adds 15-20s on top of boot's 1.5s, all visible to the user as a
    // generic "Loading wallet" hang on first import.
    //
    // Wallet usability semantics in V2 are "boot complete + services
    // operational", NOT "first sync done". The `transactionStore` already
    // serves the persistent UI state; balances/transactions stream
    // progressively through `watchBalanceFor` / `watchTransactions` as
    // the orchestrator's first sync completes per chain. UI surfaces
    // sync progress via `syncStateProvider` if it wants to render an
    // indicator.
    logger.info('app.start.ready', {});
    BootTracer.mark('lifecycle.ready');
    _emit(currentState.copyWith(
      phase: AppPhase.ready,
      readyAt: clock.now(),
    ));

    unawaited(_kickoffSyncInBackground());
    return Right(currentState);
  }

  Future<void> _kickoffSyncInBackground() async {
    logger.info('app.start.sync_begin', {});
    BootTracer.mark('lifecycle.sync.begin');
    try {
      await sync.start();
      BootTracer.mark('lifecycle.sync.settled');
      logger.info('app.start.sync_settled', {});
    } catch (e, st) {
      BootTracer.mark('lifecycle.sync.failed', {'err': '$e'});
      logger.error('app.sync.start.failed',
          {'error': '$e'}, error: e, stackTrace: st);
    }
  }

  @override
  Future<void> shutdown() async {
    if (currentState.phase == AppPhase.terminated) return;
    _emit(currentState.copyWith(phase: AppPhase.shuttingDown));
    await sync.stop();
    await boot.shutdown();
    _emit(currentState.copyWith(phase: AppPhase.terminated));
  }

  @override
  Future<Either<Failure, Unit>> deleteWalletAndReimport() async {
    logger.info('app.reimport.begin', {});
    // `DeleteWalletUseCase.call()` already runs `sync.stop()` then
    // `boot.shutdown()` before wiping. Calling them here too caused two
    // shutdowns back-to-back, each paying the per-disconnect timeout
    // budget — so a wedged liquid disconnect doubled the user-visible
    // delete latency for no benefit.
    final r = await deleteWallet();
    if (r.isLeft()) {
      logger.error('app.reimport.delete_failed', {});
      return r;
    }
    _emit(const AppState(phase: AppPhase.uninitialized));
    logger.info('app.reimport.end', {});
    return const Right(unit);
  }

  void _emit(AppState s) {
    if (_state.isClosed) return;
    logger.debug('app.state.emit', {'phase': s.phase.name});
    _state.add(s);
  }

  @override
  Future<void> dispose() async {
    await shutdown();
    await _state.close();
  }
}
