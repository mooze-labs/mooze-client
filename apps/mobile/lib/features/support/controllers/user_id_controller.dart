import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';

/// The support code of the user: the user id of the API.
///
/// The id never changes for a wallet, and the user service saves it on each
/// answer of `/users/me`. A saved id shows at once, with no request, so the
/// screen works offline and for an account that the API refuses. Only
/// without a saved id does the controller ask the API.
class UserIdController extends StateNotifier<AsyncValue<String?>> {
  final Ref _ref;

  UserIdController(this._ref) : super(const AsyncValue.loading()) {
    final saved = _ref.read(userIdStorageServiceProvider).read();
    if (saved != null) {
      state = AsyncValue.data(saved);
    } else {
      _fetchUserId();
    }
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
