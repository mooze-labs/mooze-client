import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../entities.dart';
import '../services/user_service.dart';
import 'level_change_provider.dart';
import 'user_service_provider.dart';

/// The user of `/users/me`: the level, the progress, and the limits.
final userDataProvider =
    AsyncNotifierProvider<UserDataNotifier, Either<String, User>>(
      UserDataNotifier.new,
    );

/// Shows the saved answer of `/users/me` at once, and asks the API again in
/// the background.
/// 
class UserDataNotifier extends AsyncNotifier<Either<String, User>> {
  /// False once this build is replaced or disposed. A late answer of an old
  /// build then changes nothing.
  bool Function() _isCurrent = () => false;

  @override
  FutureOr<Either<String, User>> build() {
    final service = ref.watch(userServiceProvider);
    final cache = ref.watch(userDataCacheServiceProvider);
    var current = true;
    ref.onDispose(() => current = false);
    _isCurrent = () => current;

    ref.listen(levelChangeStreamProvider, (_, next) {
      if (!next.hasValue) return;
      final saved = cache.read();
      if (saved != null) state = AsyncData(Right(saved));
    });

    final saved = cache.read();
    if (saved == null) return service.getUser().run();
    unawaited(_refresh(service));
    return Right(saved);
  }

  Future<void> _refresh(UserService service) async {
    final isCurrent = _isCurrent;
    final fresh = await service.getUser().run();
    if (!isCurrent()) return;
    if (fresh.isRight()) state = AsyncData(fresh);
  }

  /// Asks the API now and waits for the answer, for a pull to refresh. A
  /// failure keeps what shows.
  Future<void> refresh() => _refresh(ref.read(userServiceProvider));
}
