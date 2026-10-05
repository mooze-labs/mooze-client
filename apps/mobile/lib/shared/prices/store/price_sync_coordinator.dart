import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'price_quotes_notifier.dart';

class PriceSyncCoordinator {
  PriceSyncCoordinator(this._ref, {Duration interval = const Duration(seconds: 30)}) {
    _timer = Timer.periodic(interval, (_) => _tick());
  }

  final Ref _ref;
  Timer? _timer;

  void _tick() {
    final notifier = _ref.read(priceQuotesProvider.notifier);
    unawaited(notifier.refresh());
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

final priceSyncCoordinatorProvider = Provider<PriceSyncCoordinator>((ref) {
  ref.keepAlive();
  final coord = PriceSyncCoordinator(ref);
  ref.onDispose(coord.dispose);
  return coord;
});
