import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../entities.dart';
import '../services/user_service_impl.dart';
import 'user_service_provider.dart';

/// Single source of truth for `/users/me`.
///
/// All user-derived providers (`userInfoProvider`, `levelsProvider`, etc.)
/// and screens that need user data must read this provider. Multiple
/// concurrent watchers share one Riverpod-cached future, so a cold
/// home-screen paint produces exactly one network call.
///
/// `keepAlive` is intentional: user data is needed throughout the app
/// lifetime. Auto-disposing caused refetch storms when transient
/// listeners (e.g. retry buttons, dialogs) dropped to zero and bounced
/// back. To force a refetch, call `ref.invalidate(userDataProvider)` —
/// the provider invalidates the service-level cache before refetching,
/// guaranteeing fresh data.
final userDataProvider = FutureProvider<Either<String, User>>((ref) async {
  final userService = ref.read(userServiceProvider);

  // When the provider rebuilds (first read or explicit invalidate),
  // bypass the service-level TTL so callers see fresh data. Concurrent
  // direct callers (developer screen, support controller, etc.) still
  // get coalesced through the service's in-flight Future.
  if (userService is UserServiceImpl) {
    userService.invalidateUserCache();
  }

  return userService.getUser().run();
});
