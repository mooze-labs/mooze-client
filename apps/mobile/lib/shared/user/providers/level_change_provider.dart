import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entities/level_change.dart';
import '../services/user_service_impl.dart';
import 'user_service_provider.dart';

final levelChangeStreamProvider = StreamProvider<LevelChange>((ref) {
  final userService = ref.watch(userServiceProvider);

  if (userService is UserServiceImpl) {
    return userService.levelChanges;
  }

  return const Stream.empty();
});

final lastLevelChangeProvider = Provider<LevelChange?>((ref) {
  final levelChangeAsync = ref.watch(levelChangeStreamProvider);

  return levelChangeAsync.whenData((change) => change).value;
});
