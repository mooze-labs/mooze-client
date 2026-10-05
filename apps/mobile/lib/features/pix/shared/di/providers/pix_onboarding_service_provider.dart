import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/features/pix/shared/data/services/pix_onboarding_service.dart';

final pixOnboardingServiceProvider = Provider<PixOnboardingService>((ref) {
  return PixOnboardingService(ref.watch(moozeCoreProvider.future));
});
