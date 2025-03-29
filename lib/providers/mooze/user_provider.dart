import 'package:mooze_mobile/models/user.dart';
import 'package:mooze_mobile/services/mooze/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_provider.g.dart';

const String backendUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: "api.mooze.app",
);

@riverpod
UserService userService(Ref ref) {
  return UserService(backendUrl: backendUrl);
}

@riverpod
Future<String?> getUserId(Ref ref) async {
  final service = ref.watch(userServiceProvider);
  final userId = service.getUserId();
}

@riverpod
Future<User?> getUserDetails(Ref ref) async {
  final service = ref.watch(userServiceProvider);
  final userId = service.getUserDetails();
}
