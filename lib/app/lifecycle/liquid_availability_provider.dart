import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/liquid_availability.dart';
import '../../domain/services/liquid_wallet_service.dart';
import '../../domain/services/service_state.dart';
import '../di/v2_providers.dart';

/// Reactive snapshot of the Liquid layer's availability.
///
/// `LiquidWalletServiceImpl` (LWK) is the only Liquid engine, so the
/// snapshot follows its lifecycle: [LiquidAvailability.operational] while
/// LWK is connected, [LiquidAvailability.unavailable] otherwise.
/// [LiquidAvailability.degraded] is no longer produced; it meant "only the
/// Breez fallback is up", and Breez is gone.
///
/// Consumers should still gate UI states off **this**, not off
/// `lwk.isOperational` directly, so the rule lives in one place.
final liquidAvailabilityProvider = StreamProvider<LiquidAvailability>((ref) {
  final lwk = ref.watch(liquidWalletServiceProvider);
  return _watch(lwk);
});

Stream<LiquidAvailability> _watch(LiquidWalletService lwk) async* {
  // Seed with the current snapshot so the first listener gets an
  // immediate emission (matches `ReplayValueStream` semantics on the
  // underlying service).
  yield _resolve(lwk.currentState);
  await for (final s in lwk.state) {
    yield _resolve(s);
  }
}

LiquidAvailability _resolve(ServiceState lwk) => lwk.isOperational
    ? LiquidAvailability.operational
    : LiquidAvailability.unavailable;
