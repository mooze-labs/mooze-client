import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/referral_input/domain/usecases/apply_referral_code_usecase.dart';
import 'package:mooze_mobile/features/referral_input/domain/usecases/get_existing_referral_usecase.dart';
import 'package:mooze_mobile/features/referral_input/presentation/providers/usecase_providers.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

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
  final GetExistingReferralUseCase _getExistingReferralUseCase;
  final ApplyReferralCodeUseCase _applyReferralCodeUseCase;

  ReferralInputController({
    required GetExistingReferralUseCase getExistingReferralUseCase,
    required ApplyReferralCodeUseCase applyReferralCodeUseCase,
  }) : _getExistingReferralUseCase = getExistingReferralUseCase,
       _applyReferralCodeUseCase = applyReferralCodeUseCase,
       super(const ReferralInputState()) {
    checkExistingReferralCode();
  }

  Future<void> checkExistingReferralCode() async {
    final result = await _getExistingReferralUseCase();

    result.fold(
      (code) {
        if (code != null && code.isNotEmpty) {
          state = state.copyWith(existingReferralCode: code);
        } else {
          state = state.copyWith(clearExistingReferralCode: true);
        }
      },
      (error) {
        state = state.copyWith(clearExistingReferralCode: true);
      },
    );
  }

  Future<bool> applyReferralCode(String code) async {
    if (code.isEmpty) return false;

    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    final result = await _applyReferralCodeUseCase(code);

    return result.fold(
      (_) {
        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
          existingReferralCode: code,
        );
        return true;
      },
      (error) {
        state = state.copyWith(isLoading: false, error: error);
        return false;
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

final referralInputControllerProvider =
    StateNotifierProvider<ReferralInputController, ReferralInputState>((ref) {
      final getExistingReferralUseCase = ref.watch(
        getExistingReferralUseCaseProvider,
      );
      final applyReferralCodeUseCase = ref.watch(
        applyReferralCodeUseCaseProvider,
      );
      return ReferralInputController(
        getExistingReferralUseCase: getExistingReferralUseCase,
        applyReferralCodeUseCase: applyReferralCodeUseCase,
      );
    });
