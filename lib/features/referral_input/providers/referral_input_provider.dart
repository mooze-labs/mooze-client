import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/referral_input_controller.dart';
import 'package:mooze_mobile/features/referral_input/providers/user_service_provider.dart';

final referralInputControllerProvider =
    StateNotifierProvider<ReferralInputController, ReferralInputState>((ref) {
      final userService = ref.watch(userServiceProvider);
      return ReferralInputController(userService: userService);
    });
