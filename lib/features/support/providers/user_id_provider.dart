import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/user_id_controller.dart';

final userIdControllerProvider =
    StateNotifierProvider.autoDispose<UserIdController, AsyncValue<String?>>((
      ref,
    ) {
      return UserIdController(ref);
    });
