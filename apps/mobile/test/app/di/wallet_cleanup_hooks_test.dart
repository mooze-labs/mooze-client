import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mooze_mobile/app/di/wallet_cleanup_hooks.dart';
import 'package:mooze_mobile/features/setup/presentation/providers/onboarding_provider.dart';

void main() {
  test(
    'after a wallet delete, the next launch shows the onboarding again',
    () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final onboarding = container.read(onboardingServiceProvider);
      await onboarding.setOnboardingCompleted();

      final resetOnboarding = container.read(
        Provider((ref) => buildOnboardingResetHook(ref)),
      );
      await resetOnboarding();

      expect(await onboarding.isOnboardingCompleted(), isFalse);
    },
  );
}
