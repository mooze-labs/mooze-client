import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/user/services/mock_referral_service.dart';
import 'package:mooze_mobile/shared/user/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReferralInputState {
  final String? existingReferralCode;
  final bool isLoading;
  final String? error;

  const ReferralInputState({
    this.existingReferralCode,
    this.isLoading = false,
    this.error,
  });

  ReferralInputState copyWith({
    String? existingReferralCode,
    bool? isLoading,
    String? error,
  }) {
    return ReferralInputState(
      existingReferralCode: existingReferralCode ?? this.existingReferralCode,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ReferralInputController extends StateNotifier<ReferralInputState> {
  final UserService _userService;
  final MockReferralService _referralService;

  ReferralInputController({
    required UserService userService,
    required MockReferralService referralService,
  }) : _userService = userService,
       _referralService = referralService,
       super(const ReferralInputState()) {
    checkExistingReferralCode();
  }

  Future<void> checkExistingReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    final existingCode = prefs.getString('referralCode');

    final userResult = await _userService.getUser().run();

    await userResult.match(
      (error) async {
        if (existingCode != null) {
          state = state.copyWith(existingReferralCode: existingCode);
        }
      },
      (user) async {
        if (user.referredBy != null) {
          state = state.copyWith(existingReferralCode: user.referredBy);
          if (existingCode == null) {
            await prefs.setString('referralCode', user.referredBy!);
          }
          return;
        }

        if (existingCode != null) {
          state = state.copyWith(existingReferralCode: existingCode);
        }
      },
    );
  }

  Future<void> validateReferralCode(String code) async {
    if (code.isEmpty) return;

    state = state.copyWith(isLoading: true, error: null);

    final validationResult =
        await _referralService.validateReferralCode(code).run();

    await validationResult.match(
      (error) async {
        state = state.copyWith(
          isLoading: false,
          error: 'Código inválido. Verifique e tente novamente.',
        );
      },
      (isValid) async {
        if (!isValid) {
          state = state.copyWith(
            isLoading: false,
            error: 'Código inválido. Verifique e tente novamente.',
          );
          return;
        }

        final result = await _userService.addReferral(code).run();

        await result.match(
          (error) async {
            state = state.copyWith(
              isLoading: false,
              error: 'Erro ao adicionar código. Tente novamente.',
            );
          },
          (_) async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('referralCode', code);
            await checkExistingReferralCode();
            state = state.copyWith(isLoading: false);
          },
        );
      },
    );
  }
}
