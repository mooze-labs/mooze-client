import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/referral_input_controller.dart';
import 'package:mooze_mobile/features/referral_input/providers/user_service_provider.dart';
import 'package:mooze_mobile/shared/user/services/mock_referral_service.dart';

final mockReferralServiceProvider = Provider<MockReferralService>((ref) {
  return MockReferralService();
});

final referralInputControllerProvider =
    StateNotifierProvider<ReferralInputController, ReferralInputState>((ref) {
      final userService = ref.watch(userServiceProvider);
      final referralService = ref.watch(mockReferralServiceProvider);
      return ReferralInputController(
        userService: userService,
        referralService: referralService,
      );
    });
