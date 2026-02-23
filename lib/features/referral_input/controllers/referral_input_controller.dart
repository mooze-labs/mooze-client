import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/user/services/user_service.dart';

class ReferralInputState {
  final String? existingReferralCode;
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const ReferralInputState({
    this.existingReferralCode,
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  ReferralInputState copyWith({
    String? existingReferralCode,
    bool? isLoading,
    String? error,
    bool? isSuccess,
    bool clearExistingReferralCode = false,
  }) {
    return ReferralInputState(
      existingReferralCode:
          clearExistingReferralCode
              ? null
              : existingReferralCode ?? this.existingReferralCode,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class ReferralInputController extends StateNotifier<ReferralInputState> {
  final UserService _userService;

  ReferralInputController({required UserService userService})
      : _userService = userService,
        super(const ReferralInputState()) {
    checkExistingReferralCode();
  }

  Future<void> checkExistingReferralCode() async {
    final userResult = await _userService.getUser().run();

    await userResult.match(
      (error) async {
        state = state.copyWith(clearExistingReferralCode: true);
      },
      (user) async {
        if (user.referredBy != null && user.referredBy!.isNotEmpty) {
          state = state.copyWith(existingReferralCode: user.referredBy);
        } else {
          state = state.copyWith(clearExistingReferralCode: true);
        }
      },
    );
  }

  Future<bool> validateReferralCode(String code) async {
    if (code.isEmpty) return false;

    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    final validationResult = await _userService.validateReferralCode(code).run();

    return await validationResult.match(
      (error) async {
        state = state.copyWith(
          isLoading: false,
          error: 'Código inválido. Verifique e tente novamente.',
        );
        return false;
      },
      (isValid) async {
        if (!isValid) {
          state = state.copyWith(
            isLoading: false,
            error: 'Código inválido. Verifique e tente novamente.',
          );
          return false;
        }

        final result = await _userService.addReferral(code).run();

        return await result.match(
          (error) async {
            state = state.copyWith(
              isLoading: false,
              error: 'Erro ao adicionar código. Tente novamente.',
            );
            return false;
          },
          (_) async {
            state = state.copyWith(
              isLoading: false,
              error: null,
              isSuccess: true,
              existingReferralCode: code,
            );
            return true;
          },
        );
      },
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void resetState() {
    state = state.copyWith(error: null, isSuccess: false);
  }

  Future<void> refreshUser() async {
    await checkExistingReferralCode();
  }
}
