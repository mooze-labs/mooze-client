import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/domain/services/service_state.dart';
import 'package:mooze_mobile/infra/breez/lightning_wallet_service_impl.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';

/// V2 BRIDGE — exposes the legacy `breezClientProvider` shape but returns
/// the SAME `BreezSdkLiquid` instance the V2 [LightningWalletServiceImpl]
/// owns.
///
/// Prior to this change the legacy provider built its own
/// `BreezSdkLiquid`, which meant **two** Breez SDK instances pointed at
/// the same `${appDocs}/breez/` working directory in the same process —
/// the V2 `WalletDirectoryGuard` could not prevent that because both
/// instances bypassed the guard. SQLite corruption was a question of
/// timing. The bridge now points the legacy provider at the single V2
/// client.
///
/// **Readiness gate.** Returns the SDK as soon as the service reaches
/// `ServiceLifecycle.connected` and runs a cheap `getInfo()` probe to
/// verify it responds. The probe failure is logged but doesn't block —
/// the caller will surface the real exception via the
/// exception-propagating handlers in `breez.dart`.
///
/// History: an earlier version tightened this to also require
/// `lastSyncAt != null` on the hypothesis that the "Liquid SDK instance
/// is not running" failures after wallet re-import were a sync race.
/// They were not (see the stale-reference invalidation above): the gate
/// would always pass on the second wallet because `lastSyncAt` is
/// preserved through the disconnect/reconnect cycle on `ServiceState`.
/// Worse, the stricter gate caused the wait loop to time out at 6s and
/// return Left on the very first read after re-import — which produced
/// the symptom "Breez wallet not available" in the legacy
/// `walletRepositoryProvider`. The gate is back to `isOperational` only.
final breezClientProvider =
    FutureProvider<Either<String, BreezSdkLiquid>>((ref) async {
  final logger = AppLoggerService();
  final service = ref.watch(lightningWalletServiceProvider)
      as LightningWalletServiceImpl;

  // **Stale-reference invalidation (added 2026-05-12 after the
  // "Liquid SDK instance is not running" reproduction).** When the user
  // deletes a wallet and imports a new one, `boot.shutdown()` calls
  // `lightning.disconnect()` which sets `_client = null` on the V2
  // service. The subsequent re-import triggers a new
  // `lightning.connect()`, producing a *fresh* `BreezSdkLiquid`. Riverpod
  // has no signal that the SDK instance changed — `lightningWalletServiceProvider`
  // is a `Provider<LightningWalletService>` whose Dart-level value
  // (the service reference) is stable across the connect/disconnect
  // cycle. Without an explicit listener this FutureProvider keeps its
  // cached `Right(oldClient)`, the legacy `walletRepositoryProvider`
  // keeps the same `BreezWallet`, and every Liquid receive on the new
  // wallet calls `prepareReceivePayment` on the disconnected SDK
  // handle — which throws `PaymentError.generic(err: Liquid SDK
  // instance is not running)`.
  //
  // The listener watches lifecycle transitions and invalidates this
  // provider whenever the service crosses the `connected` boundary in
  // EITHER direction. The `lastSeen` guard ensures we don't react to the
  // replay value emitted on subscribe (which would feedback-loop after
  // re-evaluation).
  ServiceLifecycle? lastSeen;
  final lifecycleSub = service.state.listen((s) {
    final prev = lastSeen;
    lastSeen = s.lifecycle;
    // Skip the replay/seed value emitted synchronously on subscribe — it
    // reflects the state we already evaluated against, not a transition.
    if (prev == null) return;
    // Re-evaluate on BOTH edges of the `connected` boundary:
    //   • connected → !connected (wallet delete / disconnect): drop the
    //     cached client so no caller uses a disconnected SDK handle.
    //   • !connected → connected (wallet re-import reconnect): refresh a
    //     cached `Left`. This edge is the fix for the re-import receive-
    //     address bug. While the service is down during a delete →
    //     re-import, the 30s wait loop below can time out (the manual gap
    //     — PIN entry + import — routinely exceeds 30s), so this provider
    //     resolves `Left('… stream closed …')` and caches it. The
    //     re-imported wallet's Lightning service then reaches `connected`
    //     normally, but the OLD trigger only fired when LEAVING connected
    //     — so the cached `Left` was never refreshed. The non-autoDispose
    //     `walletRepositoryProvider` (which `ref.watch`es this future)
    //     stayed `Breez: ✗` and every Breez-backed receive-address
    //     generation failed until an app restart, even though balances
    //     and transactions (the V2 path) worked. This listener survives
    //     past resolution (cancelled only on dispose), so it catches the
    //     reconnect and re-resolves to `Right(newClient)`; the repo then
    //     rebuilds through its existing watch.
    final wasConnected = prev == ServiceLifecycle.connected;
    final isConnected = s.lifecycle == ServiceLifecycle.connected;
    if (wasConnected == isConnected) return;
    logger.info(
      'breezClientProvider',
      'invalidate-self transition=${prev.name}→${s.lifecycle.name} '
          'sdkPresent=${service.sdkClient != null} '
          'reason=connected-boundary-crossed',
    );
    // Defer to the next microtask. Calling `ref.invalidateSelf()`
    // synchronously from inside a stream listener can re-enter
    // Riverpod's disposal machinery while the broadcast stream is
    // mid-dispatch — observed symptom from the 2026-05-12 repro:
    // the provider re-evaluated immediately, captured a transient
    // `disconnected` state, hit the wait-loop timeout, and returned
    // Left("stream closed without operational state") even though the
    // new wallet's `lightning.connect()` had already emitted
    // `connected`. The microtask hop lets the listener callback
    // complete, the in-flight broadcast event settle, and the
    // service's next state emission land before we tear down and
    // re-resolve.
    Future.microtask(() {
      try {
        ref.invalidateSelf();
      } catch (_) {
        // Provider already disposed — nothing to invalidate.
      }
    });
  });
  ref.onDispose(lifecycleSub.cancel);

  Future<Either<String, BreezSdkLiquid>> probeAndReturn(
    BreezSdkLiquid client,
    String reason,
  ) async {
    final state = service.currentState;
    logger.info(
      'breezClientProvider',
      'gate-passed reason=$reason '
          'lifecycle=${state.lifecycle.name} '
          'lastSyncAt=${state.lastSyncAt?.toIso8601String() ?? "null"} '
          'sdkHash=${identityHashCode(client)}',
    );
    try {
      // Cheap probe — getInfo is what every balance/receive call leans on.
      // If the SDK is half-initialized this will surface the real cause in
      // the log timeline, but we still return the client so the caller
      // sees the same error path with the propagating handlers.
      await client.getInfo();
      logger.info('breezClientProvider', 'probe-ok getInfo() returned');
    } catch (e, st) {
      logger.warning(
        'breezClientProvider',
        'probe-failed getInfo() threw — handing client back anyway so the '
            'caller surfaces the real error: $e',
        error: e,
        stackTrace: st,
      );
    }
    return Right(client);
  }

  if (service.currentState.isOperational && service.sdkClient != null) {
    return probeAndReturn(service.sdkClient!, 'fast-path-operational');
  }

  final s0 = service.currentState;
  logger.info(
    'breezClientProvider',
    'awaiting-operational '
        'lifecycle=${s0.lifecycle.name} '
        'lastSyncAt=${s0.lastSyncAt?.toIso8601String() ?? "null"} '
        'sdkPresent=${service.sdkClient != null}',
  );

  // Wait up to 30s for the service to reach operational. The boot
  // orchestrator's connect timeout is 45s, so this is generous enough
  // for the common case (cold boot ~500ms, re-import ~250ms in the
  // 2026-05-12 traces) and short enough to surface a real failure as
  // Left rather than hang the receive screen forever.
  final stateStream = service.state.timeout(
    const Duration(seconds: 30),
    onTimeout: (sink) {
      logger.warning(
        'breezClientProvider',
        'state-stream 30s timeout — service never reached operational',
      );
      sink.close();
    },
  );

  await for (final s in stateStream) {
    if (s.lifecycle == ServiceLifecycle.errored) {
      logger.error(
        'breezClientProvider',
        'lightning service errored: ${s.failure?.message ?? "unknown"}',
      );
      return Left(s.failure?.message ?? 'lightning connect failed');
    }
    if (s.isOperational && service.sdkClient != null) {
      return probeAndReturn(service.sdkClient!, 'wait-operational');
    }
  }

  if (service.currentState.isOperational && service.sdkClient != null) {
    return probeAndReturn(
      service.sdkClient!,
      'post-timeout-operational',
    );
  }
  logger.error(
    'breezClientProvider',
    'stream closed without ever reaching operational state '
        'finalLifecycle=${service.currentState.lifecycle.name} '
        'sdkPresent=${service.sdkClient != null}',
  );
  return const Left('lightning service stream closed without operational state');
});

/// Legacy disconnect-Breez bridge. V2 owns lifecycle now, so this delegates
/// to [LightningWalletServiceImpl.disconnect()]. Kept for legacy call
/// sites that still expect `ref.read(disconnectBreezClientProvider.future)`.
final disconnectBreezClientProvider =
    FutureProvider.autoDispose<bool>((ref) async {
  final service = ref.read(lightningWalletServiceProvider)
      as LightningWalletServiceImpl;
  final result = await service.disconnect();
  return result.isRight();
});

/// Legacy "clean breez data dir" bridge. V2's `WalletDirectoryGuard.wipe`
/// is the canonical surface; legacy callers (if any remain) get a
/// successful no-op since `DeleteWalletUseCase` already wipes the dir
/// after `boot.shutdown()`.
final cleanBreezDataDirectoryProvider =
    FutureProvider.autoDispose<bool>((_) async => true);

/// Legacy "is the wallet currently being deleted?" flag. The V2 pipeline
/// uses orchestrator state instead, but a few legacy code paths still
/// read this provider so we keep it as an always-false no-op.
final setWalletDeletionFlagProvider =
    Provider.family<void, bool>((ref, value) {});
