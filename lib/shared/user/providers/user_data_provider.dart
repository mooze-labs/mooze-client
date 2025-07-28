import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../entities.dart';
import 'user_service_provider.dart';

extension CacheForExtension on Ref {
  /// Keeps the provider alive for [duration].
  void cacheFor(Duration duration) {
    // Immediately prevent the state from getting destroyed.
    final link = keepAlive();
    // After duration has elapsed, we re-enable automatic disposal.
    final timer = Timer(duration, link.close);

    // Optional: when the provider is recomputed (such as with ref.watch),
    // we cancel the pending timer.
    onDispose(timer.cancel);
  }
}

final userDataProvider = FutureProvider.autoDispose<Either<String, User>>((
  ref,
) async {
  ref.cacheFor(const Duration(seconds: 60));

  final userService = ref.read(userServiceProvider);
  final result = await userService.getUser().run();
  return result;
});
