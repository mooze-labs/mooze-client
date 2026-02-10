import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/data/services/pix_onboarding_service.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';

final pixOnboardingServiceProvider = Provider<PixOnboardingService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PixOnboardingService(prefs);
});
