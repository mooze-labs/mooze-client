import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/data/services/send_funds_onboarding_service.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';

final sendFundsOnboardingServiceProvider =
    Provider<SendFundsOnboardingService>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return SendFundsOnboardingService(prefs);
    });
