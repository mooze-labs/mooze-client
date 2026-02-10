import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/swap_onboarding_service.dart';

final swapOnboardingServiceProvider = Provider<SwapOnboardingService>((ref) {
  throw UnimplementedError(
    'swapOnboardingServiceProvider must be overridden with a proper SharedPreferences instance',
  );
});

final swapOnboardingServiceFutureProvider =
    FutureProvider<SwapOnboardingService>((ref) async {
      final prefs = await SharedPreferences.getInstance();
      return SwapOnboardingService(prefs);
    });
