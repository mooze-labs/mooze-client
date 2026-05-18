import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/liquid_availability.dart';
import '../../domain/services/lightning_wallet_service.dart';
import '../../domain/services/liquid_wallet_service.dart';
import '../../domain/services/service_state.dart';
import '../di/v2_providers.dart';

/// Reactive snapshot of the Liquid layer's availability across both
/// providers — `LiquidWalletServiceImpl` (LWK, authoritative) and
/// `LightningWalletServiceImpl` (Breez, fallback).
///
/// Consumers should gate UI states off **this**, not off
/// `lwk.isOperational` directly. The historical "Liquid ready ==
/// LWK connected" assumption broke under simulator slow I/O / FFI
/// hangs / late LWK reconnects, leaving the UI empty even though
/// Breez had usable data to serve.
///
/// State stream sourcing: each service exposes a
/// `Stream<ServiceState>` via [LiquidWalletService.state] /
/// [LightningWalletService.state]. We watch both via their service
/// instances; the combined StreamProvider re-emits whenever either
/// transitions lifecycle.
///
/// **Cold start convention.** Before either service has emitted its
/// first state, the provider returns
/// [LiquidAvailability.unavailable]. Once Breez transitions to
/// connected the provider flips to [LiquidAvailability.degraded];
/// once LWK transitions to connected it flips to
/// [LiquidAvailability.operational]. State changes never regress
/// from `operational` unless LWK actually disconnects.
final liquidAvailabilityProvider = StreamProvider<LiquidAvailability>((ref) {
  final lwk = ref.watch(liquidWalletServiceProvider);
  final lightning = ref.watch(lightningWalletServiceProvider);
  return _combine(lwk, lightning);
});

Stream<LiquidAvailability> _combine(
  LiquidWalletService lwk,
  LightningWalletService lightning,
) async* {
  // Seed with the current snapshot so the first listener gets an
  // immediate emission (matches `ReplayValueStream` semantics on the
  // underlying services).
  yield _resolve(lwk.currentState, lightning.currentState);

  // Subscribe to both streams and re-emit whenever either changes.
  // `currentState` is read inside the merge — order of arrival on the
  // combined stream is irrelevant; we always compute from the latest
  // snapshot of both services.
  await for (final _ in _mergedTriggers(lwk.state, lightning.state)) {
    yield _resolve(lwk.currentState, lightning.currentState);
  }
}

LiquidAvailability _resolve(ServiceState lwk, ServiceState lightning) {
  if (lwk.isOperational) return LiquidAvailability.operational;
  if (lightning.isOperational) return LiquidAvailability.degraded;
  return LiquidAvailability.unavailable;
}

/// Lightweight merge of two streams into a single trigger stream.
/// Values are discarded — consumers re-read `currentState` from the
/// underlying services. This is a stand-in for `rxdart.merge2` so we
/// don't add a dependency for a six-line helper.
Stream<void> _mergedTriggers(Stream<ServiceState> a, Stream<ServiceState> b) {
  late final controller = StreamController<void>(sync: false);
  final sa = a.listen((_) {
    if (!controller.isClosed) controller.add(null);
  }, onError: (Object e, StackTrace st) {
    if (!controller.isClosed) controller.addError(e, st);
  });
  final sb = b.listen((_) {
    if (!controller.isClosed) controller.add(null);
  }, onError: (Object e, StackTrace st) {
    if (!controller.isClosed) controller.addError(e, st);
  });
  controller.onCancel = () async {
    await sa.cancel();
    await sb.cancel();
  };
  return controller.stream;
}
