import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/user.dart';
import 'package:mooze_mobile/services/mooze/user.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_info_provider.g.dart';

@riverpod
Future<User?> userInfo(Ref ref) async {
  ref.cacheFor(const Duration(minutes: 1));

  final userService = UserService(backendUrl: "api.mooze.app");
  final user = await userService.getUserDetails();
  return user;
}

extension CacheForExtension on Ref {
  void cacheFor(Duration duration) {
    final link = keepAlive();
    final timer = Timer(duration, link.close);

    onDispose(() {
      timer.cancel();
    });
  }
}
