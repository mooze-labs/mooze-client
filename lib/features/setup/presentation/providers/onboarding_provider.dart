import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/onboarding_service.dart';

final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  return OnboardingService();
});
