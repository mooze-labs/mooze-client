import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';

class UserIdController extends StateNotifier<AsyncValue<String?>> {
  final Ref _ref;

  UserIdController(this._ref) : super(const AsyncValue.loading()) {
    _fetchUserId();
  }

  Future<void> _fetchUserId() async {
    state = const AsyncValue.loading();

    final userService = _ref.read(userServiceProvider);
    state = await AsyncValue.guard(() async {
      final userResult = await userService.getUser().run();
      return userResult.fold(
        (error) {
          return null;
        },
        (user) {
          return user.id;
        },
      );
    });
  }

  Future<void> refresh() async {
    await _fetchUserId();
  }
}
