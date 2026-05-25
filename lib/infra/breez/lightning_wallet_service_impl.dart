import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart' as breez;
import 'package:fpdart/fpdart.dart';

import '../../domain/entities/asset.dart';
import '../../domain/entities/balance.dart' as domain;
import '../../domain/entities/broadcast_result.dart' as domain;
import '../../domain/entities/chain.dart';
import '../../domain/entities/fee_estimate.dart' as domain;
import '../../domain/entities/receive_address.dart' as domain;
import '../../domain/entities/peg.dart' as domain;
import '../../domain/entities/refund.dart' as domain;
import '../../domain/entities/send_request.dart' as domain;
import '../../domain/entities/transaction.dart' as domain;
import '../../domain/entities/wallet_credentials.dart';
import '../../domain/events/sync_outcome.dart';
import '../../domain/events/transaction_event.dart';
import '../../domain/failures/failure.dart';
import '../../domain/repositories/wallet_directory_guard.dart';
import '../../domain/services/lightning_wallet_service.dart';
import '../../shared/diagnostics/boot_tracer.dart';
import '../../domain/services/service_state.dart';
import '../../domain/services/spendable_wallet_service.dart' as spendable;
import '../../shared/clock/clock.dart';
import '../../shared/concurrency/mutex.dart';
import '../../shared/logging/structured_logger.dart';
import '../../shared/streams/replay_value_stream.dart';
import 'breez_config.dart';

/// Production Breez SDK adapter. Connect/disconnect are exclusive at SDK
/// level — the impl gates them under [_connectMutex] and acquires the
/// working directory through [WalletDirectoryGuard] so two instances cannot
/// share the same SQLite file.
class LightningWalletServiceImpl implements LightningWalletService {
  LightningWalletServiceImpl({
    required this.directoryGuard,
    required this.logger,
    required this.clock,
    this.workingDirRelative = 'breez',
    this.apiKey,
  });

  final WalletDirectoryGuard directoryGuard;
  final StructuredLogger logger;
  final Clock clock;
  final String workingDirRelative;
  final String? apiKey;

  final Mutex _connectMutex = Mutex();
  final Mutex _syncMutex = Mutex();

  breez.BreezSdkLiquid? _client;
  String? _acquiredDirectory;
  AppNetwork _network = AppNetwork.mainnet;

  final Map<String, _LnFingerprint> _seen = {};
  List<domain.Transaction> _lastList = const [];
  domain.Balance _lastBalance = domain.Balance.empty();

  final ReplayValueStream<ServiceState> _state =
      ReplayValueStream<ServiceState>.seeded(ServiceState.initial);
  final StreamController<TransactionEvent> _txController =
      StreamController<TransactionEvent>.broadcast();

  /// Subscription to the Breez SDK's live event stream
  /// (`PaymentSucceeded`, `PaymentRefundable`, `Synced`, etc). The SDK
  /// emits these the moment its internal state machine observes a
  /// change — typically seconds before our periodic `sync()` would
  /// notice. Without this, an asset swap completion (LBTC → DePix,
  /// for example) shows up as a "transaction confirmed" modal on
  /// whichever periodic / post-swap-refresh sync happens to land
  /// after Breez registered it, but the cached `_lastBalance` only
  /// updates on that sync's `c.getInfo()` call. Users saw the modal
  /// well before the home balance refreshed.
  StreamSubscription<breez.SdkEvent>? _eventSub;

  /// Debounce timer for the live-event → sync trigger. Breez can fire
  /// several events per state transition (e.g. `PaymentPending` then
  /// `PaymentSucceeded`); collapsing them into a single sync avoids
  /// thrashing the orchestrator.
  Timer? _eventSyncDebounce;

  @override
  ChainId get chain => ChainId.lightning;
  @override
  Stream<ServiceState> get state => _state.stream;
  @override
  ServiceState get currentState => _state.value;
  @override
  Stream<TransactionEvent> get transactions => _txController.stream;

  /// Underlying Breez Liquid SDK client. `null` until `connect()` succeeds
  /// and after `disconnect()`. Exposed so the legacy
  /// `WalletRepositoryImpl/breez.dart` wrapper can reuse the same SDK
  /// instance V2 owns — eliminating the duplicate-instance SQLite
  /// corruption risk that existed when the legacy `breezClientProvider`
  /// constructed its own client (both would try to open the breez working
  /// directory concurrently).
  breez.BreezSdkLiquid? get sdkClient => _client;

  @override
  Future<Either<ServiceFailure, Unit>> connect(
    WalletCredentials credentials,
  ) async {
    BootTracer.mark('lightning.connect.entered');
    final tEnter = clock.now();
    return _connectMutex.protect(() async {
      BootTracer.mark('lightning.connect.mutex_acquired', {
        'wait_ms': clock.now().difference(tEnter).inMilliseconds,
      });
      if (currentState.isOperational) {
        BootTracer.mark('lightning.connect.short_circuit');
        return const Right(unit);
      }
      _emit(ServiceLifecycle.connecting);
      _network = credentials.network;

      BootTracer.mark('lightning.dir_acquire.begin');
      final tDir = clock.now();
      final dirResult = await directoryGuard.acquire(workingDirRelative);
      BootTracer.mark('lightning.dir_acquire.end', {
        'dur_ms': clock.now().difference(tDir).inMilliseconds,
        'ok': dirResult.isRight(),
      });
      if (dirResult.isLeft()) {
        return _fail(
          'workdir acquire failed: '
          '${dirResult.swap().getOrElse((_) => const StorageFailure("?")).message}',
        );
      }
      _acquiredDirectory = dirResult.getOrElse(
        (_) => throw StateError('unreachable'),
      );

      try {
        BootTracer.mark('lightning.config_build.begin');
        final tCfg = clock.now();
        final config = await BreezConfigFactory(
          workingDir: _acquiredDirectory!,
          apiKey: apiKey,
        ).build(_network);
        BootTracer.mark('lightning.config_build.end', {
          'dur_ms': clock.now().difference(tCfg).inMilliseconds,
        });

        BootTracer.mark('lightning.sdk_connect.begin');
        final tSdk = clock.now();
        final client = await breez.connect(
          req: breez.ConnectRequest(
            mnemonic: credentials.mnemonic,
            config: config,
          ),
        );
        BootTracer.mark('lightning.sdk_connect.end', {
          'dur_ms': clock.now().difference(tSdk).inMilliseconds,
        });
        _client = client;
        // Subscribe to Breez's live event stream. Each event indicates
        // the SDK's local state machine just advanced (payment
        // succeeded, swap refundable, full network sync completed,
        // etc.) — schedule a debounced `sync()` so our cached
        // `_lastBalance` + `_lastList` follow without waiting for the
        // next periodic tick. See [_onBreezEvent].
        _eventSub = client.addEventListener().listen(
          _onBreezEvent,
          onError: (Object e, StackTrace st) {
            logger.warn('lightning.event_stream.error',
                {'error': '$e'}, error: e, stackTrace: st);
          },
        );
        _emit(ServiceLifecycle.connected, clearFailure: true);
        final totalMs = clock.now().difference(tEnter).inMilliseconds;
        BootTracer.mark('lightning.connected', {'total_ms': totalMs});
        logger.info('lightning.connected', {});
        return const Right(unit);
      } catch (e, st) {
        await directoryGuard.release(workingDirRelative);
        _acquiredDirectory = null;
        return _fail('breez connect failed: $e', cause: e, stackTrace: st);
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
        final c = _client;
        _client = null;
        _seen.clear();
        // Tear down the live event listener and any pending
        // debounced sync — both reference the SDK client we're about
        // to drop. Cancelling first avoids a "use after disconnect"
        // race where an event arrives mid-disconnect and triggers
        // `_scheduleEventSync` on a stale `_client` reference.
        await _eventSub?.cancel();
        _eventSub = null;
        _eventSyncDebounce?.cancel();
        _eventSyncDebounce = null;
        // Clear cached snapshots so a subsequent reconnect (e.g.,
        // delete + re-import with a different mnemonic) doesn't surface
        // wallet-1's data while wallet-2's first sync is still pending.
        // The defensive "fresh.assets < _lastBalance.assets keeps cache"
        // guard in `getBalance` would otherwise lock in wallet-1.
        _lastBalance = domain.Balance.empty();
        _lastList = const [];
        if (c != null) {
          await c.disconnect();
        }
        if (_acquiredDirectory != null) {
          await directoryGuard.release(workingDirRelative);
          _acquiredDirectory = null;
        }
        _emit(ServiceLifecycle.disconnected, clearFailure: true);
        logger.info('lightning.disconnected', {});
        return const Right(unit);
      } catch (e, st) {
        return _fail('breez disconnect failed: $e', cause: e, stackTrace: st);
      }
    });
  }

  @override
  Future<Either<ServiceFailure, SyncOutcome>> sync({Duration? timeout}) async {
    return _syncMutex.protect(() async {
      final c = _client;
      if (c == null || !currentState.isOperational) {
        return Left(ServiceFailure('not connected', chain: chain));
      }
      final t0 = clock.now();
      final effectiveTimeout = timeout ?? const Duration(seconds: 45);
      BootTracer.mark('breez.sync.begin', {
        'timeout_ms': effectiveTimeout.inMilliseconds,
      });
      try {
        // ─── Phase 1: Breez SDK internal sync (gRPC to Greenlight + ──
        //              local processing of the payment ledger). This
        //              is the suspected bottleneck — log start, end,
        //              and any timeout.
        final tSdkSync = clock.now();
        BootTracer.mark('breez.sync.sdk_sync.begin');
        await c.sync().timeout(effectiveTimeout);
        final sdkSyncMs = clock.now().difference(tSdkSync).inMilliseconds;
        BootTracer.mark('breez.sync.sdk_sync.end', {'dur_ms': sdkSyncMs});

        // ─── Phase 2: pull the payment list out of the SDK ──
        final tListPayments = clock.now();
        BootTracer.mark('breez.sync.list_payments.begin');
        final payments = await c.listPayments(
          req: const breez.ListPaymentsRequest(),
        );
        final listPaymentsMs =
            clock.now().difference(tListPayments).inMilliseconds;
        BootTracer.mark('breez.sync.list_payments.end', {
          'n': payments.length,
          'dur_ms': listPaymentsMs,
        });

        // ─── Phase 3: pull wallet balance/info ──
        final tGetInfo = clock.now();
        BootTracer.mark('breez.sync.get_info.begin');
        final info = await c.getInfo();
        final getInfoMs = clock.now().difference(tGetInfo).inMilliseconds;
        BootTracer.mark('breez.sync.get_info.end', {'dur_ms': getInfoMs});

        // **Source-aware emission (2026-05-18 redesign).**
        //
        // Pre-2026-05-18 this path filtered out `chain == ChainId.liquid`
        // entirely — making LWK the *exclusive* writer for Liquid txs.
        // That broke when LWK was degraded / wedged / timing out: the
        // user saw an empty transaction list even though Breez was
        // operational and had perfectly usable Liquid tx data.
        //
        // The filter is gone. Breez now emits Liquid txs again,
        // tagged with `source = TransactionSource.breez`. The
        // source-aware upsert merge in `transaction_store_impl.dart`
        // resolves the conflict deterministically:
        //
        //   - LWK is AUTHORITATIVE for chain=liquid. Once a row has
        //     `source='lwk'`, Breez's subsequent writes cannot
        //     overwrite the authoritative fields (direction, status,
        //     amount, fee, confirmations, asset, timestamp).
        //   - Breez can still update its own metadata (address, label)
        //     and fill in fields LWK left null, via COALESCE.
        //   - Pre-LWK (degraded mode), Breez writes flow through
        //     normally and the user sees the list populate.
        //
        // No filter needed here. The "rows mutate after a few seconds"
        // bug is prevented by the upsert merge, not by the filter.
        // ─── Phase 4: classify (per-payment _mapPayment) + sort.
        //              `_mapPayment` also calls `_logBreezPaymentV2`
        //              which emits the `[BREEZ-TX-V2]` debug lines.
        //              `_classifyPayments` is a thin wrapper that
        //              first pairs same-`txId` Liquid send+receive
        //              payments into a single `direction=swap` row —
        //              see its docstring.
        final tClassify = clock.now();
        BootTracer.mark('breez.sync.classify.begin', {'n': payments.length});
        final mapped = _classifyPayments(payments);
        final classifyMs = clock.now().difference(tClassify).inMilliseconds;
        BootTracer.mark('breez.sync.classify.end', {
          'n_in': payments.length,
          'n_out': mapped.length,
          'dur_ms': classifyMs,
          'per_payment_us':
              payments.isEmpty ? 0 : (classifyMs * 1000) ~/ payments.length,
        });

        final tSort = clock.now();
        mapped.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        BootTracer.mark('breez.sync.sort.end', {
          'dur_ms': clock.now().difference(tSort).inMilliseconds,
        });

        // ─── Phase 5: diff against previous + emit per change ──
        final tDiff = clock.now();
        BootTracer.mark('breez.sync.diff.begin', {'n': mapped.length});
        final changed = _diffAndEmit(mapped);
        BootTracer.mark('breez.sync.diff.end', {
          'changed': changed,
          'dur_ms': clock.now().difference(tDiff).inMilliseconds,
        });

        _lastList = mapped;
        _lastBalance = _mapBalance(info);

        _emit(
          ServiceLifecycle.connected,
          lastSyncAt: clock.now(),
          clearFailure: true,
        );

        final totalMs = clock.now().difference(t0).inMilliseconds;
        BootTracer.mark('breez.sync.end', {
          'total_ms': totalMs,
          'sdk_sync_ms': sdkSyncMs,
          'list_payments_ms': listPaymentsMs,
          'classify_ms': classifyMs,
          'fetched': mapped.length,
          'changed': changed,
        });

        return Right(
          SyncOutcome(
            chain: chain,
            fetched: mapped.length,
            changed: changed,
            duration: clock.now().difference(t0),
          ),
        );
      } on TimeoutException catch (e, st) {
        final totalMs = clock.now().difference(t0).inMilliseconds;
        // Critical: when this fires we know the SDK call exceeded its
        // budget. Stamp the wall-clock so we can correlate against
        // heartbeats / network logs.
        BootTracer.mark('breez.sync.timeout', {
          'total_ms': totalMs,
          'budget_ms': effectiveTimeout.inMilliseconds,
        });
        return Left(
          ServiceFailure(
            'breez sync timeout',
            chain: chain,
            cause: e,
            stackTrace: st,
          ),
        );
      } catch (e, st) {
        final totalMs = clock.now().difference(t0).inMilliseconds;
        BootTracer.mark('breez.sync.error', {
          'total_ms': totalMs,
          'error': e.toString(),
        });
        return Left(
          ServiceFailure(
            'breez sync failed: $e',
            chain: chain,
            cause: e,
            stackTrace: st,
          ),
        );
      }
    });
  }

  // ─────────────────────────────────────────── refund surface
  //
  // Translates Breez SDK types (`RefundableSwap`, `RecommendedFees`,
  // `PrepareRefundResponse`, `RefundResponse`) into V2 domain types so
  // feature/UI layers don't import `flutter_breez_liquid`.

  @override
  Future<Either<ServiceFailure, List<domain.RefundableSwap>>>
  listRefundables() async {
    final c = _client;
    if (c == null || !currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    try {
      final breezList = await c.listRefundables();
      final mapped =
          breezList
              .map(
                (r) => domain.RefundableSwap(
                  swapAddress: r.swapAddress,
                  amountSat: r.amountSat.toInt(),
                  lastRefundTxId: r.lastRefundTxId,
                  timestamp:
                      r.timestamp == 0
                          ? null
                          : DateTime.fromMillisecondsSinceEpoch(
                            r.timestamp * 1000,
                          ),
                ),
              )
              .toList();
      return Right(mapped);
    } catch (e, st) {
      return Left(
        ServiceFailure(
          'breez listRefundables failed: $e',
          chain: chain,
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<ServiceFailure, String?>> findChainSwapIdByLockup({
    required String lockupTxId,
  }) async {
    final c = _client;
    if (c == null || !currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    try {
      // Scan the SDK payment list for the chain swap whose lockup tx
      // we just broadcast. `lockupTxId` is the BDK-side txid the
      // helper captured on peg-in (or the LWK-side txid on peg-out).
      // Matching the payment by lockup is the only way to recover the
      // Breez short swap id (`wCaunaTNZaHv`-style) — `prepareReceive
      // Payment` doesn't surface it at prepare time.
      final payments = await c.listPayments(
        req: const breez.ListPaymentsRequest(),
      );
      for (final p in payments) {
        final d = p.details;
        if (d is breez.PaymentDetails_Bitcoin && d.lockupTxId == lockupTxId) {
          return Right(d.swapId);
        }
      }
      return const Right(null);
    } catch (e, st) {
      return Left(
        ServiceFailure(
          'breez findChainSwapIdByLockup failed: $e',
          chain: chain,
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<ServiceFailure, domain.MempoolFees>> recommendedFees() async {
    final c = _client;
    if (c == null || !currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    try {
      final f = await c.recommendedFees();
      return Right(
        domain.MempoolFees(
          minimumFee: f.minimumFee.toInt(),
          economyFee: f.economyFee.toInt(),
          hourFee: f.hourFee.toInt(),
          halfHourFee: f.halfHourFee.toInt(),
          fastestFee: f.fastestFee.toInt(),
        ),
      );
    } catch (e, st) {
      return Left(
        ServiceFailure(
          'breez recommendedFees failed: $e',
          chain: chain,
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<ServiceFailure, domain.PrepareRefundOutcome>> prepareRefund(
    domain.PrepareRefundParams params,
  ) async {
    final c = _client;
    if (c == null || !currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    try {
      final resp = await c.prepareRefund(
        req: breez.PrepareRefundRequest(
          swapAddress: params.swapAddress,
          refundAddress: params.refundAddress,
          feeRateSatPerVbyte: params.feeRateSatPerVbyte,
        ),
      );
      return Right(
        domain.PrepareRefundOutcome(
          txVsize: resp.txVsize,
          feesSat: resp.txFeeSat.toInt(),
          refundTxId: resp.lastRefundTxId,
        ),
      );
    } catch (e, st) {
      return Left(
        ServiceFailure(
          'breez prepareRefund failed: $e',
          chain: chain,
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<ServiceFailure, domain.RefundOutcome>> executeRefund(
    domain.ExecuteRefundParams params,
  ) async {
    final c = _client;
    if (c == null || !currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    try {
      final resp = await c.refund(
        req: breez.RefundRequest(
          swapAddress: params.swapAddress,
          refundAddress: params.refundAddress,
          feeRateSatPerVbyte: params.feeRateSatPerVbyte,
        ),
      );
      // No synthetic TransactionEvent here — the refund tx surfaces on
      // the next sync's `listPayments` walk and `_diffAndEmit` handles
      // it through the standard pipeline. (Refunds happen rarely; the
      // ~2-min sync delay is acceptable UX.)
      return Right(domain.RefundOutcome(refundTxId: resp.refundTxId));
    } catch (e, st) {
      return Left(
        ServiceFailure(
          'breez executeRefund failed: $e',
          chain: chain,
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<ServiceFailure, Unit>> rescan({
    required Duration window,
  }) async {
    final c = _client;
    if (c == null || !currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    try {
      // The Breez SDK provides on-chain rescan via sync() with internal
      // window control; full forced rescan APIs vary by version. As a
      // baseline we re-call sync(); higher-fidelity rescan can be wired by
      // swapping this for `c.rescanOnchainSwaps()` if exposed.
      await c.sync().timeout(
        window > const Duration(seconds: 60)
            ? const Duration(seconds: 60)
            : window,
      );
      return const Right(unit);
    } catch (e, st) {
      return Left(
        ServiceFailure(
          'breez rescan failed: $e',
          chain: chain,
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<ServiceFailure, List<domain.Transaction>>>
  listTransactions() async {
    if (currentState.isOperational) return Right(_lastList);
    return Left(ServiceFailure('not connected', chain: chain));
  }

  @override
  Future<Either<ServiceFailure, domain.Balance>> getBalance() async {
    // Cache-only read. `c.getInfo()` is needless work on this path —
    // `sync()` already refreshes `_lastBalance` from a single `getInfo`
    // while holding `_syncMutex`, which is also where the Breez
    // mid-sync `assetBalances == []` race used to surface. Reading the
    // cache here means callers never observe that transient state and
    // never pay an extra Breez RPC on hot paths like Home rebuild.
    if (!currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    return Right(_lastBalance);
  }

  // ─────────────────────────────────────────── SpendableWalletService
  //
  // Liquid on-chain (L-BTC + Liquid assets) routes through Breez Liquid
  // SDK's two-step prepareSendPayment + sendPayment API — same SDK, same
  // call shape, that legacy `wallet_repository_impl/breez.dart` uses
  // (see `prepareLayer2BitcoinSendTransaction`, `prepareAssetSendTransaction`,
  // and `sendLayer2Transaction`). The two-step is hidden from callers
  // here: `estimateFee` runs only the prepare step; `sendOnchain` runs
  // both. Lightning sends use [SpendableLightningService] below — the
  // SDK call surface overlaps but the domain shape (prepared-token
  // pattern) differs.
  //
  // Bitcoin on-chain (`ChainId.bitcoin`) is rejected — it lives on
  // `BitcoinWalletService` (BDK), not here.

  @override
  Future<Either<ServiceFailure, domain.FeeEstimate>> estimateFee(
    domain.SendRequest request,
  ) async {
    if (request.chain != ChainId.liquid) {
      return Left(
        ServiceFailure(
          'lightning service only handles Liquid on-chain estimates '
          '(got: ${request.chain.name})',
          chain: chain,
        ),
      );
    }
    final c = _client;
    if (c == null || !currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    try {
      final prepareResp = await c.prepareSendPayment(
        req: _buildPrepareSendRequest(request),
      );
      return Right(
        domain.FeeEstimate(
          chain: ChainId.liquid,
          priority: request.feePriority,
          absoluteFeeSat: (prepareResp.feesSat ?? BigInt.zero).toInt(),
          // Breez Liquid does not surface a sat/vB rate to the client —
          // fee is the absolute amount the SDK computed for this specific
          // payment shape. Leave the rate null; UI shows the absolute fee.
        ),
      );
    } catch (e, st) {
      return Left(
        ServiceFailure(
          'breez prepareSend failed: $e',
          chain: chain,
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<ServiceFailure, domain.ReceiveAddress>> nextReceiveAddress({
    String? assetId,
    String? label,
  }) async {
    final c = _client;
    if (c == null || !currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    try {
      final prepareReq = breez.PrepareReceiveRequest(
        paymentMethod: breez.PaymentMethod.liquidAddress,
        amount:
            assetId == null
                ? null
                : breez.ReceiveAmount_Asset(assetId: assetId),
      );
      final prepareResp = await c.prepareReceivePayment(req: prepareReq);
      final receiveResp = await c.receivePayment(
        req: breez.ReceivePaymentRequest(
          prepareResponse: prepareResp,
          description: label,
        ),
      );
      return Right(
        domain.ReceiveAddress(
          chain: ChainId.liquid,
          address: receiveResp.destination,
          assetId: assetId,
          label: label,
        ),
      );
    } catch (e, st) {
      return Left(
        ServiceFailure(
          'breez receivePayment (liquid) failed: $e',
          chain: chain,
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<ServiceFailure, domain.BroadcastResult>> sendOnchain(
    domain.SendRequest request,
  ) async {
    if (request.chain != ChainId.liquid) {
      return Left(
        ServiceFailure(
          'lightning service only handles Liquid on-chain sends '
          '(got: ${request.chain.name})',
          chain: chain,
        ),
      );
    }
    final c = _client;
    if (c == null || !currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    try {
      // Step 1: prepare. Same call as estimateFee, but we keep the
      // PrepareSendResponse to feed into sendPayment so the SDK doesn't
      // re-prepare and risk picking different UTXOs / a stale fee.
      final prepareResp = await c.prepareSendPayment(
        req: _buildPrepareSendRequest(request),
      );

      // Step 2: send. Returns a SendPaymentResponse whose `payment` is the
      // newly-broadcast Payment. Breez emits this same payment via its
      // event stream too; sync() picks it up on next tick.
      final sendResp = await c.sendPayment(
        req: breez.SendPaymentRequest(prepareResponse: prepareResp),
      );

      final mapped = _mapPayment(sendResp.payment);
      if (mapped == null) {
        return Left(
          ServiceFailure(
            'breez sendPayment returned an unmappable Payment',
            chain: chain,
          ),
        );
      }

      // Update local view + emit synthetic event so the orchestrator's
      // single-writer pipeline persists this tx via transactionStore.upsert
      // BEFORE any UI subscriber sees it. This preserves the
      // persist-before-republish invariant on the broadcast path.
      _seen[mapped.id] = _LnFingerprint(mapped.status, mapped.confirmations);
      _lastList = [mapped, ..._lastList];
      _emitTx(
        TransactionEvent(
          kind: TransactionEventKind.created,
          transaction: mapped,
          observedAt: clock.now(),
        ),
      );

      // Refresh `_lastBalance` so the home / swap screen reads
      // post-spend balance the moment they invalidate, not the
      // pre-spend cached value. See `_refreshCachedBalanceAfterSpend`.
      await _refreshCachedBalanceAfterSpend();

      return Right(
        domain.BroadcastResult(
          chain: ChainId.liquid,
          txId: mapped.id,
          transaction: mapped,
          feePaidSat: (prepareResp.feesSat ?? BigInt.zero).toInt(),
        ),
      );
    } catch (e, st) {
      return Left(
        ServiceFailure(
          'breez sendPayment (liquid) failed: $e',
          chain: chain,
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  // ─────────────────────────────────────────── SpendableLightningService
  //
  // Lightning sends are a *transport rail* on top of the unified Liquid
  // balance (per product clarification 2026-05-06). This service does
  // NOT track a separate Lightning balance — outgoing Lightning payments
  // are funded from the Breez L-BTC pool and reduce it; the
  // `Asset.lbtc.resolutionChains == [lightning, liquid]` aggregation in
  // `WalletRepositoryImpl` ensures users see the unified balance shrink.
  //
  // Two destination shapes ride through this surface:
  //   - BOLT-11 invoices and amount-encoded variants → Breez
  //     `prepareSendPayment` + `sendPayment` (same SDK calls Liquid
  //     sends use; only the `destination` string differs).
  //   - LNURL-pay endpoints and Lightning Addresses → Breez
  //     `parse(input) → InputType_LnUrlPay` then `prepareLnurlPay` +
  //     `lnurlPay`. Lightning Addresses are LNURL-pay URLs in disguise;
  //     Breez handles both via `parse` so we treat them uniformly.
  //
  // The `PreparedLightningSend.opaqueToken` carries either a
  // `breez.PrepareSendResponse` or a `breez.PrepareLnUrlPayResponse`.
  // `sendLightning` cast-dispatches without callers caring which kind
  // they got back. `LightningSendRequest` validates exactly-one-set
  // before reaching here.

  @override
  Future<Either<ServiceFailure, domain.PreparedLightningSend>> prepareSend(
    domain.LightningSendRequest request,
  ) async {
    final c = _client;
    if (c == null || !currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    final destination = request.bolt11 ?? request.lnurl ?? request.lnAddress;
    if (destination == null || destination.isEmpty) {
      return Left(
        ServiceFailure(
          'LightningSendRequest requires exactly one of bolt11 / lnurl / lnAddress',
          chain: chain,
        ),
      );
    }
    try {
      final inputType = await c.parse(input: destination);

      if (inputType is breez.InputType_Bolt11) {
        // BOLT-11 invoice. Amount comes from the invoice unless it's a
        // zero-amount one, in which case `request.amountSat` is required.
        final invoiceAmount = inputType.invoice.amountMsat?.toInt() ?? 0;
        final invoiceAmountSat =
            invoiceAmount > 0 ? (invoiceAmount ~/ 1000) : null;
        if (invoiceAmountSat == null && request.amountSat == null) {
          return Left(
            ServiceFailure(
              'zero-amount invoice requires amountSat',
              chain: chain,
            ),
          );
        }
        final effectiveAmountSat = invoiceAmountSat ?? request.amountSat!;
        final prepareResp = await c.prepareSendPayment(
          req: breez.PrepareSendRequest(
            destination: destination,
            // For zero-amount invoices, supply the amount; for
            // amount-encoded ones, omit (Breez ignores any override and
            // uses the invoice's encoded amount).
            amount:
                invoiceAmountSat == null
                    ? breez.PayAmount_Bitcoin(
                      receiverAmountSat: BigInt.from(effectiveAmountSat),
                    )
                    : null,
          ),
        );
        return Right(
          domain.PreparedLightningSend(
            opaqueToken: prepareResp,
            amountSat: effectiveAmountSat,
            feeEstimate: domain.FeeEstimate(
              chain: ChainId.lightning,
              priority: domain.FeePriority.medium,
              absoluteFeeSat: (prepareResp.feesSat ?? BigInt.zero).toInt(),
            ),
            destinationDescription: 'BOLT-11 invoice',
          ),
        );
      }

      if (inputType is breez.InputType_LnUrlPay) {
        // LNURL-pay (or Lightning Address). Amount is required from the
        // request — LNURL-pay endpoints typically expose a min/max range
        // and the user picks within it; Breez validates against the
        // endpoint's data on prepare.
        final amountSat = request.amountSat;
        if (amountSat == null) {
          return Left(
            ServiceFailure(
              'LNURL-pay / Lightning Address requires amountSat',
              chain: chain,
            ),
          );
        }
        final prepareResp = await c.prepareLnurlPay(
          req: breez.PrepareLnUrlPayRequest(
            data: inputType.data,
            amount: breez.PayAmount_Bitcoin(
              receiverAmountSat: BigInt.from(amountSat),
            ),
            bip353Address: inputType.bip353Address,
            comment: request.label,
            validateSuccessActionUrl: true,
          ),
        );
        return Right(
          domain.PreparedLightningSend(
            opaqueToken: prepareResp,
            amountSat: amountSat,
            feeEstimate: domain.FeeEstimate(
              chain: ChainId.lightning,
              priority: domain.FeePriority.medium,
              absoluteFeeSat: prepareResp.feesSat.toInt(),
            ),
            destinationDescription: request.lnAddress ?? 'LNURL-pay endpoint',
          ),
        );
      }

      return Left(
        ServiceFailure(
          'unsupported Lightning destination type: ${inputType.runtimeType}',
          chain: chain,
        ),
      );
    } catch (e, st) {
      return Left(
        ServiceFailure(
          'breez prepare lightning send failed: $e',
          chain: chain,
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<ServiceFailure, domain.BroadcastResult>> sendLightning(
    domain.PreparedLightningSend prepared,
  ) async {
    final c = _client;
    if (c == null || !currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    try {
      // Cast-dispatch on the opaque token. The shape was chosen at
      // prepare time; callers must round-trip the same prepared object
      // they received (the `LightningSendRequest` invariant).
      final token = prepared.opaqueToken;
      breez.Payment? payment;

      if (token is breez.PrepareSendResponse) {
        // BOLT-11 path.
        final sendResp = await c.sendPayment(
          req: breez.SendPaymentRequest(prepareResponse: token),
        );
        payment = sendResp.payment;
      } else if (token is breez.PrepareLnUrlPayResponse) {
        // LNURL-pay path. `lnurlPay` returns a sealed result — endpoint
        // success contains the payment; pay-error / endpoint-error are
        // typed failures.
        final result = await c.lnurlPay(
          req: breez.LnUrlPayRequest(prepareResponse: token),
        );
        if (result is breez.LnUrlPayResult_EndpointSuccess) {
          payment = result.data.payment;
        } else if (result is breez.LnUrlPayResult_PayError) {
          return Left(
            ServiceFailure(
              'LNURL-pay endpoint rejected: ${result.data.reason}',
              chain: chain,
            ),
          );
        } else if (result is breez.LnUrlPayResult_EndpointError) {
          return Left(
            ServiceFailure(
              'LNURL-pay endpoint error: ${result.data.reason}',
              chain: chain,
            ),
          );
        } else {
          return Left(
            ServiceFailure(
              'LNURL-pay returned unknown result: ${result.runtimeType}',
              chain: chain,
            ),
          );
        }
      } else {
        return Left(
          ServiceFailure(
            'PreparedLightningSend.opaqueToken has unsupported type '
            '(${token.runtimeType}) — was it constructed by prepareSend?',
            chain: chain,
          ),
        );
      }

      final mapped = _mapPayment(payment);
      if (mapped == null) {
        return Left(
          ServiceFailure(
            'breez Lightning send returned an unmappable Payment',
            chain: chain,
          ),
        );
      }

      // Persist-before-republish — same invariant as Liquid + Bitcoin.
      // Note `_chainFromDetails` already tagged `mapped.chain` as
      // `ChainId.lightning` for a Lightning payment; tx history shows
      // it as a Lightning payment, balance aggregation pulls from the
      // L-BTC pool (per the unified-balance model).
      _seen[mapped.id] = _LnFingerprint(mapped.status, mapped.confirmations);
      _lastList = [mapped, ..._lastList];
      _emitTx(
        TransactionEvent(
          kind: TransactionEventKind.created,
          transaction: mapped,
          observedAt: clock.now(),
        ),
      );

      // Refresh `_lastBalance` so the L-BTC pool (which absorbs the
      // Lightning HTLC cost) shows the new value the moment the UI
      // invalidates after this send.
      await _refreshCachedBalanceAfterSpend();

      // Extract preimage if available (proves payment for BOLT-11).
      String? preimage;
      final details = payment.details;
      if (details is breez.PaymentDetails_Lightning) {
        preimage = details.preimage;
      }

      return Right(
        domain.BroadcastResult(
          chain: ChainId.lightning,
          txId: mapped.id,
          transaction: mapped,
          feePaidSat: payment.feesSat.toInt(),
          preimage: preimage,
        ),
      );
    } catch (e, st) {
      return Left(
        ServiceFailure(
          'breez sendLightning failed: $e',
          chain: chain,
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<ServiceFailure, domain.ReceiveAddress>> createInvoice({
    required int amountSat,
    String? description,
    Duration? expiry,
  }) async {
    final c = _client;
    if (c == null || !currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    try {
      final prepareReq = breez.PrepareReceiveRequest(
        paymentMethod: breez.PaymentMethod.bolt11Invoice,
        amount: breez.ReceiveAmount_Bitcoin(
          payerAmountSat: BigInt.from(amountSat),
        ),
      );
      final prepareResp = await c.prepareReceivePayment(req: prepareReq);
      final receiveResp = await c.receivePayment(
        req: breez.ReceivePaymentRequest(
          prepareResponse: prepareResp,
          description: description,
        ),
      );
      // Breez returns the invoice in `destination` for BOLT-11 receives.
      return Right(
        domain.ReceiveAddress(
          chain: ChainId.lightning,
          bolt11: receiveResp.destination,
          amountSat: amountSat,
          label: description,
          expiresAt: expiry == null ? null : clock.now().add(expiry),
        ),
      );
    } catch (e, st) {
      return Left(
        ServiceFailure(
          'breez createInvoice failed: $e',
          chain: chain,
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<ServiceFailure, spendable.LightningPaymentLimits>>
  fetchLightningLimits() async {
    final c = _client;
    if (c == null || !currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    try {
      final limits = await c.fetchLightningLimits();
      return Right(
        spendable.LightningPaymentLimits(
          minSendSat: limits.send.minSat.toInt(),
          maxSendSat: limits.send.maxSat.toInt(),
          minReceiveSat: limits.receive.minSat.toInt(),
          maxReceiveSat: limits.receive.maxSat.toInt(),
        ),
      );
    } catch (e, st) {
      return Left(
        ServiceFailure(
          'breez fetchLightningLimits failed: $e',
          chain: chain,
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<ServiceFailure, spendable.OnchainPaymentLimits>>
  fetchOnchainLimits() async {
    final c = _client;
    if (c == null || !currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    try {
      final limits = await c.fetchOnchainLimits();
      return Right(
        spendable.OnchainPaymentLimits(
          minSendSat: limits.send.minSat.toInt(),
          maxSendSat: limits.send.maxSat.toInt(),
          minReceiveSat: limits.receive.minSat.toInt(),
          maxReceiveSat: limits.receive.maxSat.toInt(),
        ),
      );
    } catch (e, st) {
      return Left(
        ServiceFailure(
          'breez fetchOnchainLimits failed: $e',
          chain: chain,
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  // ─────────────────────────────────────────── peg surface
  //
  // Peg-in: Breez allocates a one-time Bitcoin deposit address backed by
  // a submarine swap. The repository orchestrates the actual on-chain
  // BTC tx via `BitcoinWalletService` (BDK).
  //
  // Peg-out: Breez handles the L-BTC → BTC swap end-to-end via
  // `preparePayOnchain` + `payOnchain`. The persist-before-republish
  // contract is honoured by emitting a synthetic created-event right
  // after `payOnchain` succeeds, identical to the Liquid `sendOnchain`
  // path.

  @override
  Future<Either<ServiceFailure, ({String bitcoinAddress, int breezFeesSat})>>
  preparePegInDeposit({required int payerAmountSat}) async {
    final c = _client;
    if (c == null || !currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    try {
      final prepareReq = breez.PrepareReceiveRequest(
        paymentMethod: breez.PaymentMethod.bitcoinAddress,
        amount: breez.ReceiveAmount_Bitcoin(
          payerAmountSat: BigInt.from(payerAmountSat),
        ),
      );
      final prepareResp = await c.prepareReceivePayment(req: prepareReq);
      final receiveResp = await c.receivePayment(
        req: breez.ReceivePaymentRequest(prepareResponse: prepareResp),
      );
      return Right((
        bitcoinAddress: receiveResp.destination,
        breezFeesSat: prepareResp.feesSat.toInt(),
      ));
    } catch (e, st) {
      return Left(
        ServiceFailure(
          'breez preparePegInDeposit failed: $e',
          chain: chain,
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<ServiceFailure, domain.PegOutQuote>> preparePegOut(
    domain.PegOutRequest request,
  ) async {
    final c = _client;
    if (c == null || !currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    try {
      final amount =
          request.drain
              ? breez.PayAmount_Drain()
              : breez.PayAmount_Bitcoin(
                receiverAmountSat: BigInt.from(request.receiverAmountSat),
              );
      final prepareResp = await c.preparePayOnchain(
        req: breez.PreparePayOnchainRequest(
          amount: amount,
          feeRateSatPerVbyte: request.feeRateSatPerVByte?.toInt(),
        ),
      );
      return Right(
        domain.PegOutQuote(
          receiverAmountSat: prepareResp.receiverAmountSat.toInt(),
          totalFeesSat: prepareResp.totalFeesSat.toInt(),
        ),
      );
    } catch (e, st) {
      return Left(
        ServiceFailure(
          'breez preparePegOut failed: $e',
          chain: chain,
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<ServiceFailure, domain.BroadcastResult>> executePegOut(
    domain.PegOutRequest request,
  ) async {
    final c = _client;
    if (c == null || !currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    try {
      // Re-derive the prepare response from the canonical request — V2
      // stateless philosophy. UTXO selection / fee rate runs against
      // the current wallet state, not against a stale prepared object.
      final amount =
          request.drain
              ? breez.PayAmount_Drain()
              : breez.PayAmount_Bitcoin(
                receiverAmountSat: BigInt.from(request.receiverAmountSat),
              );
      final prepareResp = await c.preparePayOnchain(
        req: breez.PreparePayOnchainRequest(
          amount: amount,
          feeRateSatPerVbyte: request.feeRateSatPerVByte?.toInt(),
        ),
      );
      final payResp = await c.payOnchain(
        req: breez.PayOnchainRequest(
          address: request.btcAddress,
          prepareResponse: prepareResp,
        ),
      );

      final mapped = _mapPayment(payResp.payment);
      if (mapped == null) {
        return Left(
          ServiceFailure(
            'breez payOnchain returned an unmappable Payment',
            chain: chain,
          ),
        );
      }

      // Persist-before-republish: synthetic event so the orchestrator's
      // single-writer pipeline upserts this tx via transactionStore
      // BEFORE any UI subscriber sees it.
      _seen[mapped.id] = _LnFingerprint(mapped.status, mapped.confirmations);
      _lastList = [mapped, ..._lastList];
      _emitTx(
        TransactionEvent(
          kind: TransactionEventKind.created,
          transaction: mapped,
          observedAt: clock.now(),
        ),
      );

      // Refresh `_lastBalance` so the L-BTC pool reflects the lockup
      // immediately. The user-facing BTC balance on the destination
      // side only updates when the swap legs settle on-chain, but the
      // L-BTC debit is real the moment payOnchain returns.
      await _refreshCachedBalanceAfterSpend();

      return Right(
        domain.BroadcastResult(
          chain: ChainId.bitcoin,
          txId: mapped.id,
          transaction: mapped,
          feePaidSat: prepareResp.totalFeesSat.toInt(),
        ),
      );
    } catch (e, st) {
      return Left(
        ServiceFailure(
          'breez payOnchain failed: $e',
          chain: chain,
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  // ─────────────────────────────────────────── helpers

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
    final f = ServiceFailure(
      msg,
      chain: chain,
      cause: cause,
      stackTrace: stackTrace,
    );
    if (!_state.isClosed) {
      _state.add(
        currentState.copyWith(lifecycle: ServiceLifecycle.errored, failure: f),
      );
    }
    logger.warn('lightning.fail', {'reason': msg});
    return Left(f);
  }

  /// Translate a domain [domain.SendRequest] for Liquid into a Breez
  /// [breez.PrepareSendRequest]. Routing rules (preserved from legacy
  /// `wallet_repository_impl/breez.dart`):
  ///
  ///   - assetId == null → L-BTC send → `PayAmount_Bitcoin(receiverAmountSat)`.
  ///   - assetId != null → asset send → `PayAmount_Asset(toAsset,
  ///     receiverAmount, estimateAssetFees: false)`. Asset amounts are
  ///     supplied as a double in the SDK; we convert from satoshi units
  ///     using 8 decimals (matches `Asset.fromSatoshis` for stables).
  ///   - drain (or legacy subtractFeeFromAmount) → `PayAmount_Drain()`.
  ///     The destination receives the wallet balance minus fees;
  ///     `request.amountSat` is ignored.
  ///
  /// Asset units note: Breez's `PayAmount_Asset.receiverAmount` is in
  /// the asset's whole-unit precision (e.g. USDt amount in dollars),
  /// NOT in satoshis. Legacy converts via `amount / 1e8` — we do the
  /// same. If product later wants per-asset precision (a 6-decimal
  /// stable, say), this conversion needs revisiting; tracked as a
  /// follow-up to the Asset entity.
  breez.PrepareSendRequest _buildPrepareSendRequest(
    domain.SendRequest request,
  ) {
    final breez.PayAmount payAmount;
    if (request.drain || request.subtractFeeFromAmount) {
      payAmount = breez.PayAmount_Drain();
    } else if (request.assetId == null) {
      payAmount = breez.PayAmount_Bitcoin(
        receiverAmountSat: BigInt.from(request.amountSat),
      );
    } else {
      payAmount = breez.PayAmount_Asset(
        toAsset: request.assetId!,
        receiverAmount: request.amountSat / 100000000,
        estimateAssetFees: false,
      );
    }
    return breez.PrepareSendRequest(
      destination: request.destination,
      amount: payAmount,
    );
  }

  /// Classify a list of Breez payments into `Transaction`s, pairing
  /// internal Liquid swaps before per-payment mapping.
  ///
  /// Why this exists: a single Liquid asset swap (DePix → L-BTC, etc.)
  /// surfaces in `listPayments()` as **two** `Payment` rows sharing the
  /// same `txId` — one `paymentType=send` carrying the outgoing asset,
  /// one `paymentType=receive` carrying the incoming asset. Mapped
  /// individually by `_mapPayment`, both produce `Transaction` rows
  /// with the same `(id, chain)` primary key. The store's
  /// `INSERT OR REPLACE` then collapses them into a single row whose
  /// `direction` is whichever payment was written last (non-
  /// deterministic ordering). Result on the home screen: the user
  /// sees the swap render as a one-sided "DePix received" row until
  /// the next LWK sync re-classifies the underlying Liquid tx as a
  /// proper swap and overwrites it via the source-aware merge.
  ///
  /// This pairing pass detects the
  /// `(txId, two Liquid payments, opposite paymentType, distinct
  /// assetId)` shape up front and emits a single `Transaction` with
  /// `direction=swap`, `fromAssetId/toAssetId`, and matching sent/
  /// received amounts — exactly the shape the V2 ↔ legacy adapter and
  /// the home list's swap row already understand. Unpaired payments
  /// (Lightning HTLCs, Bitcoin peg legs, regular one-sided Liquid
  /// sends/receives) fall through to `_mapPayment` unchanged.
  List<domain.Transaction> _classifyPayments(List<breez.Payment> payments) {
    // Group same-txId Liquid payments together. We only collect into
    // `groups` when the payment is a Liquid one with a non-empty txId
    // (the swap shape we need to pair); everything else maps
    // individually below.
    final groups = <String, List<breez.Payment>>{};
    final passthrough = <breez.Payment>[];
    for (final p in payments) {
      final txId = p.txId;
      final isLiquidWithTxId = p.details is breez.PaymentDetails_Liquid &&
          txId != null &&
          txId.isNotEmpty;
      if (isLiquidWithTxId) {
        (groups[txId] ??= <breez.Payment>[]).add(p);
      } else {
        passthrough.add(p);
      }
    }

    final out = <domain.Transaction>[];

    groups.forEach((txId, group) {
      // The pairing pattern we care about: exactly two Liquid
      // payments, one `send` + one `receive`, with distinct
      // assetIds. Any other shape (single payment, two same-type
      // payments, same-asset pair, etc.) we treat as ordinary and
      // fall back to per-payment mapping so we don't lose data.
      final isSwapPair = group.length == 2 &&
          group.first.paymentType != group.last.paymentType &&
          (group.first.details as breez.PaymentDetails_Liquid).assetId !=
              (group.last.details as breez.PaymentDetails_Liquid).assetId;
      if (!isSwapPair) {
        for (final p in group) {
          final tx = _mapPayment(p);
          if (tx != null) out.add(tx);
        }
        return;
      }
      final swapTx = _mergeLiquidSwapPair(txId, group);
      if (swapTx != null) {
        out.add(swapTx);
      } else {
        // Defensive: degraded merge falls back to per-payment.
        for (final p in group) {
          final tx = _mapPayment(p);
          if (tx != null) out.add(tx);
        }
      }
    });

    for (final p in passthrough) {
      final tx = _mapPayment(p);
      if (tx != null) out.add(tx);
    }
    return out;
  }

  /// Merge a confirmed send+receive pair sharing the same Liquid `txId`
  /// into a single `direction=swap` transaction. Both payments are
  /// already logged via `_logBreezPaymentV2` from inside `_mapPayment`
  /// when we fall through; we replay the log here too so the per-leg
  /// breakdown stays visible in `[BREEZ-TX-V2]` for forensics.
  domain.Transaction? _mergeLiquidSwapPair(
    String txId,
    List<breez.Payment> pair,
  ) {
    final sendP = pair.firstWhere(
      (p) => p.paymentType == breez.PaymentType.send,
      orElse: () => pair.first,
    );
    final receiveP = pair.firstWhere(
      (p) => p.paymentType == breez.PaymentType.receive,
      orElse: () => pair.last,
    );
    // Both logs preserved so the raw payment shape is still
    // forensically reachable; if the user reports a misclassified
    // swap we can replay both legs from the trace.
    _logBreezPaymentV2(sendP);
    _logBreezPaymentV2(receiveP);

    final sendDetails = sendP.details as breez.PaymentDetails_Liquid;
    final recvDetails = receiveP.details as breez.PaymentDetails_Liquid;

    // Both payments share `txId`; pick the most-progressed status of
    // the pair (a confirmed swap can briefly hold one leg as
    // confirmed and the other as pending while Breez catches up).
    domain.TransactionStatus pickStatus() {
      final s1 = _statusFromPaymentState(sendP.status);
      final s2 = _statusFromPaymentState(receiveP.status);
      // Order of dominance: confirmed > pending > failed.
      if (s1 == domain.TransactionStatus.confirmed ||
          s2 == domain.TransactionStatus.confirmed) {
        return domain.TransactionStatus.confirmed;
      }
      if (s1 == domain.TransactionStatus.pending ||
          s2 == domain.TransactionStatus.pending) {
        return domain.TransactionStatus.pending;
      }
      return domain.TransactionStatus.failed;
    }

    final status = pickStatus();
    final sentAmount = _amountSatFromPayment(sendP);
    final receivedAmount = _amountSatFromPayment(receiveP);
    final feeSat = sendP.feesSat.toInt() + receiveP.feesSat.toInt();
    // Newer of the two timestamps — the swap completed as of the
    // later one (typically the receive leg confirming).
    final ts = sendP.timestamp > receiveP.timestamp
        ? sendP.timestamp
        : receiveP.timestamp;

    return domain.Transaction(
      id: txId,
      chain: ChainId.liquid,
      direction: domain.TransactionDirection.swap,
      status: status,
      // Headline amount matches the V2 swap convention (the sent
      // leg). `_v2ToLegacy` in the home adapter reads `amountSat` for
      // the row's primary value display.
      amountSat: sentAmount,
      feeSat: feeSat,
      timestamp: DateTime.fromMillisecondsSinceEpoch(ts * 1000),
      confirmations: status == domain.TransactionStatus.confirmed ? 1 : 0,
      assetId: sendDetails.assetId,
      fromAssetId: sendDetails.assetId,
      toAssetId: recvDetails.assetId,
      sentAmountSat: sentAmount,
      receivedAmountSat: receivedAmount,
      source: domain.TransactionSource.breez,
    );
  }

  domain.TransactionStatus _statusFromPaymentState(breez.PaymentState s) {
    return switch (s) {
      breez.PaymentState.complete => domain.TransactionStatus.confirmed,
      breez.PaymentState.failed => domain.TransactionStatus.failed,
      breez.PaymentState.timedOut => domain.TransactionStatus.failed,
      _ => domain.TransactionStatus.pending,
    };
  }

  /// Map a Breez `Payment` to a domain `Transaction`.
  ///
  /// Breez Liquid SDK is a multi-rail engine — `listPayments` returns
  /// Lightning, Liquid on-chain, AND Bitcoin (via swap) payments through
  /// the same call. This helper dispatches `chain` from
  /// `PaymentDetails` rather than from the service's chain field, so a
  /// synced direct-Liquid send is tagged `liquid` and a Lightning HTLC
  /// is tagged `lightning`. Critical for the unified-balance model: tx
  /// history shows the rail; balance aggregation already correctly
  /// resolves both rails as Liquid (per `Asset.lbtc.resolutionChains`).
  ///
  /// Identity (deterministic, never null for legitimate payments):
  ///   - Lightning: `payment.txId` (settlement chain txid, post-swap) →
  ///     `details.invoice` (BOLT-11) → `details.swapId`.
  ///   - Bitcoin (Breez peg/peg-out swap): `payment.txId` →
  ///     `details.claimTxId` → `details.swapId`.
  ///   - Liquid: `payment.txId` → `details.destination` → empty (the
  ///     direct-Liquid path always supplies `txId` post-broadcast).
  ///
  /// Returns null only if the payment has no usable identifier (which in
  /// practice never happens for a Breez-emitted payment — defensive).
  domain.Transaction? _mapPayment(breez.Payment p) {
    _logBreezPaymentV2(p);
    final id = _resolvePaymentId(p);
    if (id.isEmpty) return null;
    final dir =
        p.paymentType == breez.PaymentType.receive
            ? domain.TransactionDirection.incoming
            : domain.TransactionDirection.outgoing;
    final status = switch (p.status) {
      breez.PaymentState.complete => domain.TransactionStatus.confirmed,
      breez.PaymentState.failed => domain.TransactionStatus.failed,
      breez.PaymentState.timedOut => domain.TransactionStatus.failed,
      _ => domain.TransactionStatus.pending,
    };
    return domain.Transaction(
      id: id,
      chain: _chainFromDetails(p.details),
      direction: dir,
      status: status,
      amountSat: _amountSatFromPayment(p),
      feeSat: p.feesSat.toInt(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(p.timestamp * 1000),
      confirmations: status == domain.TransactionStatus.confirmed ? 1 : 0,
      // For Liquid payments (L-BTC + USDT + DePix etc.), Breez surfaces
      // the asset identity on `PaymentDetails_Liquid.assetId`. Without
      // this, every Liquid tx came through as `assetId: null` and the
      // V2-legacy adapter mapped them all to `Asset.lbtc` — which is
      // why USDT/DePix transactions used to render as LBTC with zero
      // balance in the home tx list. Lightning + Bitcoin payments stay
      // assetId-null (their identity is the chain itself).
      assetId: _assetIdFromDetails(p.details),
      // Source tag: Breez is authoritative for chain=lightning (only
      // writer there) and tentative for chain=liquid (the source-aware
      // upsert merge lets LWK overwrite the authoritative fields when
      // LWK eventually classifies the same row). For chain=bitcoin
      // (peg-in/out swap settlements) Breez writes the swap-settlement
      // metadata; BDK handles user-initiated sends/receives — the two
      // typically have different (id, chain) keys so no conflict.
      source: domain.TransactionSource.breez,
    );
  }

  String? _assetIdFromDetails(breez.PaymentDetails details) {
    if (details is breez.PaymentDetails_Liquid) return details.assetId;
    return null;
  }

  /// Resolve the on-row amount for a Breez Payment. For L-BTC, Lightning,
  /// and Bitcoin (peg) payments, `Payment.amountSat` is authoritative. For
  /// **Liquid asset** payments (USDT, DePix, …) the new SDK does NOT put
  /// the asset amount into `amountSat` — that field carries 0 (or only the
  /// L-BTC fee component). The asset amount lives on
  /// `details.assetInfo.amount` as a double in whole units (e.g. 1.5 USDT).
  /// We rescale that into the 8-decimal sat-equivalent the legacy
  /// formatters already expect (`Asset.formatBalance` divides by 1e8). If
  /// `assetInfo` is absent (older SDK or pending/incomplete tx), fall back
  /// to `amountSat` so we don't regress L-BTC on the same code path.
  int _amountSatFromPayment(breez.Payment p) {
    final details = p.details;
    if (details is breez.PaymentDetails_Liquid &&
        details.assetId != lbtcAssetId) {
      final info = details.assetInfo;
      if (info != null) {
        return (info.amount * 100000000).round();
      }
    }
    return p.amountSat.toInt();
  }

  /// Mirror legacy `BreezTransactionDto._parseTxid` resolution order so
  /// deterministic identity is preserved across all three rails.
  String _resolvePaymentId(breez.Payment p) {
    final txId = p.txId;
    if (txId != null && txId.isNotEmpty) return txId;
    final details = p.details;
    if (details is breez.PaymentDetails_Lightning) {
      final invoice = details.invoice;
      if (invoice != null && invoice.isNotEmpty) return invoice;
      return details.swapId;
    }
    if (details is breez.PaymentDetails_Bitcoin) {
      final claim = details.claimTxId;
      if (claim != null && claim.isNotEmpty) return claim;
      return details.swapId;
    }
    if (details is breez.PaymentDetails_Liquid) {
      // Direct Liquid sends (the path our V2 `sendOnchain` exercises)
      // always have `txId` — the fall-through here is the receive case
      // mid-confirmation, which produces `destination` (the receive
      // address). Better than empty for dedup.
      return details.destination;
    }
    return '';
  }

  ChainId _chainFromDetails(breez.PaymentDetails details) {
    if (details is breez.PaymentDetails_Lightning) return ChainId.lightning;
    if (details is breez.PaymentDetails_Bitcoin) return ChainId.bitcoin;
    if (details is breez.PaymentDetails_Liquid) return ChainId.liquid;
    // Defensive: if Breez adds a new variant, default to Liquid since
    // that's the canonical rail for this service. The orchestrator will
    // still receive the event; logs will catch the unknown variant.
    return ChainId.liquid;
  }

  /// Map a Breez `GetInfoResponse` into a domain `Balance`.
  ///
  /// **Unified L2-first model** (per product clarification 2026-05-06):
  /// the wallet is fundamentally Liquid; Lightning is a transport rail,
  /// not a balance domain. Therefore Breez Liquid SDK's
  /// `info.walletInfo.balanceSat` — internally the L-BTC pool that backs
  /// both on-chain Liquid spends AND Lightning capacity — is tagged here
  /// with `assetId: lbtcAssetId`. This makes `Asset.lbtc` resolution in
  /// the wallet repository pick it up correctly (the resolver matches
  /// non-native-bitcoin assets by asset id, not by null).
  ///
  /// Why this is a fix, not a change: legacy `wallet_repository_impl.dart`
  /// stores Breez output into `Map<Asset, BigInt>` keyed by `Asset.lbtc`
  /// (see `_getBreezBalance` in `wallet_repository_impl/breez.dart`).
  /// The V2 model expressed the same mapping via the `(chain, assetId)`
  /// tuple but my Phase 2.2 implementation left `assetId` null, which
  /// would have caused `Asset.lbtc` to skip the Breez entry and fall
  /// through to LWK only — losing any Liquid-side L-BTC visibility from
  /// the Breez view (and producing wrong balances when Breez and LWK
  /// disagree, which they can during a sync window).
  ///
  /// `chain` stays `ChainId.lightning` for service tagging — the resolver
  /// in `Asset.lbtc.resolutionChains` ([lightning, liquid]) routes here
  /// first because Breez has the freshest view of L-BTC settlements
  /// (Lightning HTLCs settle into the Breez L-BTC pool immediately;
  /// LWK's electrum view is one block behind).
  domain.Balance _mapBalance(breez.GetInfoResponse info) {
    final pending =
        (info.walletInfo.pendingSendSat + info.walletInfo.pendingReceiveSat)
            .toInt();
    final assets = <domain.AssetBalance>[
      domain.AssetBalance(
        chain: chain,
        assetId: lbtcAssetId,
        amountSat: info.walletInfo.balanceSat.toInt(),
        ticker: 'BTC',
        pendingSat: pending,
      ),
    ];
    for (final ab in info.walletInfo.assetBalances) {
      // Skip L-BTC: `walletInfo.balanceSat` above is already the native
      // L-BTC balance, and current Breez Liquid SDK versions also
      // emit L-BTC inside `assetBalances`. Adding both would double
      // the L-BTC value because `WalletRepositoryImpl._extractAssetAmount`
      // defensively sums every entry matching the asset id on a chain.
      if (ab.assetId == lbtcAssetId) continue;
      assets.add(
        domain.AssetBalance(
          chain: chain,
          assetId: ab.assetId,
          amountSat: ab.balanceSat.toInt(),
          ticker: ab.ticker,
        ),
      );
    }
    return domain.Balance(assets: assets, snapshotAt: clock.now());
  }

  int _diffAndEmit(List<domain.Transaction> incoming) {
    var changes = 0;
    final now = clock.now();
    for (final tx in incoming) {
      final prev = _seen[tx.id];
      if (prev == null) {
        changes++;
        _seen[tx.id] = _LnFingerprint(tx.status, tx.confirmations);
        _emitTx(
          TransactionEvent(
            kind: TransactionEventKind.created,
            transaction: tx,
            observedAt: now,
          ),
        );
        continue;
      }
      if (prev.status != tx.status) {
        changes++;
        _seen[tx.id] = _LnFingerprint(tx.status, tx.confirmations);
        _emitTx(
          TransactionEvent(
            kind: TransactionEventKind.statusChanged,
            transaction: tx,
            previousStatus: prev.status,
            previousConfirmations: prev.confirmations,
            observedAt: now,
          ),
        );
      } else if (prev.confirmations != tx.confirmations) {
        changes++;
        _seen[tx.id] = _LnFingerprint(tx.status, tx.confirmations);
        _emitTx(
          TransactionEvent(
            kind: TransactionEventKind.confirmationsChanged,
            transaction: tx,
            previousStatus: prev.status,
            previousConfirmations: prev.confirmations,
            observedAt: now,
          ),
        );
      }
    }
    return changes;
  }

  void _emitTx(TransactionEvent e) {
    if (!_txController.isClosed) _txController.add(e);
  }

  /// Refresh `_lastBalance` immediately after a spend so the UI's cached
  /// balance reflects the new state without waiting for the next sync.
  ///
  /// Problem this solves: `sendOnchain` / `sendLightning` / `executePegOut`
  /// update `_seen`, `_lastList`, and emit a synthetic `TransactionEvent`,
  /// but they do NOT touch `_lastBalance`. The cache is only refreshed
  /// inside `sync()`. When the user finishes a swap (DePix → L-BTC, say,
  /// emptying their DePix), the swap screen invalidates
  /// `allBalancesProvider`, the home re-reads, and the chain service
  /// returns the STALE pre-swap `_lastBalance` — the user sees DePix
  /// "available" that doesn't actually exist anymore until the next sync
  /// tick (~1–2 s) catches up.
  ///
  /// After `c.sendPayment` / `c.payOnchain` returns, the Breez SDK has
  /// already committed the UTXO change locally — `c.getInfo()` returns
  /// the post-spend balance. Pulling it here (without a full sync) keeps
  /// the spend path under ~100 ms total and guarantees the next
  /// `getBalance()` call sees the new state.
  ///
  /// Best-effort: a failure here doesn't fail the send (we still
  /// broadcasted successfully). It just means we fall back to the
  /// existing sync-driven refresh.
  Future<void> _refreshCachedBalanceAfterSpend() async {
    final c = _client;
    if (c == null || !currentState.isOperational) return;
    try {
      final tInfo = clock.now();
      final info = await c.getInfo();
      _lastBalance = _mapBalance(info);
      BootTracer.mark('breez.post_spend.balance_refreshed', {
        'dur_ms': clock.now().difference(tInfo).inMilliseconds,
        'asset_count': _lastBalance.assets.length,
      });
    } catch (e) {
      logger.warn('lightning.post_spend.balance_refresh_failed', {
        'error': '$e',
      });
    }
  }

  @override
  Future<Either<ServiceFailure, domain.Balance>> refreshBalance() async {
    final c = _client;
    if (c == null || !currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    try {
      final t0 = clock.now();
      final info = await c.getInfo();
      _lastBalance = _mapBalance(info);
      BootTracer.mark('breez.refresh_balance.ok', {
        'dur_ms': clock.now().difference(t0).inMilliseconds,
        'asset_count': _lastBalance.assets.length,
      });
      return Right(_lastBalance);
    } catch (e, st) {
      logger.warn('lightning.refresh_balance.failed', {'error': '$e'});
      return Left(
        ServiceFailure(
          'breez refreshBalance failed: $e',
          chain: chain,
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<ServiceFailure, domain.Balance>> applyOptimisticBalanceDelta({
    required Map<String, int> deltas,
  }) async {
    if (!currentState.isOperational) {
      return Left(ServiceFailure('not connected', chain: chain));
    }
    if (deltas.isEmpty) return Right(_lastBalance);
    final prev = _lastBalance;
    // Re-build the asset list applying deltas. Preserve any asset that
    // already exists in `_lastBalance`; insert a new entry for ids the
    // cache hadn't surfaced yet (e.g. user just received their first
    // DePix via swap and Breez hasn't reported the row yet).
    final byId = <String?, domain.AssetBalance>{
      for (final ab in prev.assets) ab.assetId: ab,
    };
    deltas.forEach((assetId, deltaSat) {
      final existing = byId[assetId];
      if (existing == null) {
        if (deltaSat <= 0) return; // can't go negative on an unseen asset
        byId[assetId] = domain.AssetBalance(
          chain: chain,
          assetId: assetId,
          amountSat: deltaSat,
          ticker: assetId == lbtcAssetId ? 'BTC' : null,
        );
        return;
      }
      final next = existing.amountSat + deltaSat;
      byId[assetId] = domain.AssetBalance(
        chain: existing.chain,
        assetId: existing.assetId,
        amountSat: next < 0 ? 0 : next,
        precision: existing.precision,
        ticker: existing.ticker,
        pendingSat: existing.pendingSat,
      );
    });
    _lastBalance = domain.Balance(
      assets: byId.values.toList(growable: false),
      snapshotAt: clock.now(),
    );
    BootTracer.mark('breez.optimistic_delta.applied', {
      'delta_count': deltas.length,
      'asset_count': _lastBalance.assets.length,
    });
    return Right(_lastBalance);
  }

  /// Live Breez SDK event handler. Reacts ONLY to payment-level events
  /// — `Synced` / `DataSynced` / `SyncFailed` are filtered out
  /// because they fire after every internal SDK sync, including the
  /// one our own `sync()` triggers. Reacting to `Synced` produces a
  /// trivial feedback loop:
  ///
  ///   our sync() → c.sync() → SDK emits Synced → debounce → sync()
  ///   → c.sync() → SDK emits Synced → ...
  ///
  /// A profiled trace caught this in the wild — Breez was running
  /// ~one sync per second indefinitely, each one returning
  /// `changed=0`, draining battery and rate-limiting the Greenlight
  /// endpoint.
  ///
  /// Payment events (`PaymentSucceeded`, `PaymentPending`,
  /// `PaymentRefundable`, `PaymentRefunded`, `PaymentRefundPending`,
  /// `PaymentFailed`, `PaymentWaitingConfirmation`,
  /// `PaymentWaitingFeeAcceptance`) genuinely signal "a payment
  /// you care about just transitioned" — those are exactly the
  /// moments where we want a fast `sync()` so the cached
  /// `_lastBalance` + the home tx list pick up the new state
  /// without waiting for the periodic tick.
  ///
  /// Coalesced via [_eventSyncDebounce] so a burst of related
  /// events (e.g. `PaymentPending` followed seconds later by
  /// `PaymentSucceeded` for the same swap) collapses into one sync.
  void _onBreezEvent(breez.SdkEvent event) {
    if (!currentState.isOperational) return;
    // Sync-related events are noise — they fire as a consequence of
    // our own `c.sync()` call. Filter them at the top so we don't
    // burn CPU scheduling debounces that will only spam more syncs.
    if (event is breez.SdkEvent_Synced ||
        event is breez.SdkEvent_DataSynced ||
        event is breez.SdkEvent_SyncFailed) {
      return;
    }
    _eventSyncDebounce?.cancel();
    _eventSyncDebounce = Timer(const Duration(milliseconds: 250), () {
      _eventSyncDebounce = null;
      if (!currentState.isOperational) return;
      BootTracer.mark('breez.event.sync_trigger', {
        'event': event.runtimeType.toString(),
      });
      // Fire-and-forget: errors are surfaced via the regular sync
      // failure path; we don't want to leak a synchronous throw out
      // of the event listener.
      unawaited(sync().catchError((Object e, StackTrace st) {
        logger.warn('lightning.event_triggered_sync.failed',
            {'error': '$e'}, error: e, stackTrace: st);
        return Left<ServiceFailure, SyncOutcome>(
          ServiceFailure('event-triggered sync threw: $e',
              chain: chain, cause: e, stackTrace: st),
        );
      }));
    });
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    if (!_txController.isClosed) await _txController.close();
    await _state.close();
  }
}

class _LnFingerprint {
  const _LnFingerprint(this.status, this.confirmations);
  final domain.TransactionStatus status;
  final int confirmations;
}

/// Dumps every Breez Payment that flows through the V2 mapper.
///
/// Tag: `[BREEZ-TX-V2]`. The V2 path collapses `PaymentState.refundable`
/// into `TransactionStatus.pending` (see the switch at the top of
/// `_mapPayment`), so the only way to see a refundable swap from this
/// pipeline is to inspect the raw `p.status` here — that's the whole
/// point of the dump.
void _logBreezPaymentV2(breez.Payment p) {
  if (!kDebugMode) return;
  final d = p.details;
  String detailsLine;
  if (d is breez.PaymentDetails_Bitcoin) {
    detailsLine =
        'Bitcoin{swapId=${d.swapId}, addr=${d.bitcoinAddress}, '
        'lockupTx=${d.lockupTxId}, claimTx=${d.claimTxId}, '
        'refundTx=${d.refundTxId}, refundAmtSat=${d.refundTxAmountSat}}';
  } else if (d is breez.PaymentDetails_Lightning) {
    final inv = d.invoice;
    detailsLine =
        'Lightning{swapId=${d.swapId}, '
        'invoice=${inv == null ? "null" : "${inv.substring(0, inv.length.clamp(0, 20))}…"}, '
        'preimage=${d.preimage}, claimTx=${d.claimTxId}, '
        'refundTx=${d.refundTxId}}';
  } else if (d is breez.PaymentDetails_Liquid) {
    detailsLine = 'Liquid{dest=${d.destination}, assetId=${d.assetId}}';
  } else {
    detailsLine = 'unknown(${d.runtimeType})';
  }

  debugPrint(
    '[BREEZ-TX-V2] state=${p.status.name} type=${p.paymentType.name} '
    'amountSat=${p.amountSat} feesSat=${p.feesSat} '
    'txId=${p.txId} ts=${p.timestamp} '
    'details=$detailsLine',
  );
}
