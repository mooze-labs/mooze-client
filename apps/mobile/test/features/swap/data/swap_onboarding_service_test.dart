import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/swap/data/services/swap_onboarding_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<SwapOnboardingService> service(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SwapOnboardingService(await SharedPreferences.getInstance());
  }

  // The first text of the BTC / L-BTC warning named Breez and a manual
  // refund in the app. A user who read it sees the SideSwap text once.
  test('a user who saw the old warning sees the new one', () async {
    final onboarding = await service({'btc_lbtc_swap_warning_shown': true});

    expect(onboarding.hasSeenBtcLbtcSwapWarning(), isFalse);
  });

  test('once seen, the new warning stays seen', () async {
    final onboarding = await service({});

    await onboarding.markBtcLbtcSwapWarningAsSeen();

    expect(onboarding.hasSeenBtcLbtcSwapWarning(), isTrue);
    expect(
      (await SharedPreferences.getInstance()).getBool(
        SwapOnboardingService.btcLbtcSwapWarningKey,
      ),
      isTrue,
    );
  });
}
