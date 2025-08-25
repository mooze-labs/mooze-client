import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';

class UserIdController extends StateNotifier<AsyncValue<String?>> {
  final Ref _ref;

  UserIdController(this._ref) : super(const AsyncValue.loading()) {
    _fetchUserId();
  }

  Future<void> _fetchUserId() async {
    state = const AsyncValue.loading();
    
    // Retorna diretamente o ID mockado
    state = const AsyncValue.data('8ef2afe3b57e4405f0c1c48c3c8a13b2383016f6172aebb3841eaeb2139d0984');
    
    // final userService = _ref.read(userServiceProvider);
    // state = await AsyncValue.guard(() async {
    //   final userResult = await userService.getUser().run();
    //   return userResult.fold(
    //     (error) => null,
    //     (user) => user.id,
    //   );
    // });
  }

  Future<void> refresh() async {
    await _fetchUserId();
  }
} 
