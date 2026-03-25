import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/merchant/domain/usecases/activate_merchant_mode_usecase.dart';
import 'package:mooze_mobile/features/merchant/domain/usecases/check_merchant_mode_usecase.dart';
import 'package:mooze_mobile/features/merchant/domain/usecases/deactivate_merchant_mode_usecase.dart';
import 'package:mooze_mobile/features/merchant/domain/usecases/get_merchant_mode_origin_usecase.dart';
import 'package:mooze_mobile/features/merchant/presentation/providers/usecase_providers.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

class MerchantModeController extends StateNotifier<AsyncValue<bool>> {
  final CheckMerchantModeUseCase _checkUseCase;
  final ActivateMerchantModeUseCase _activateUseCase;
  final DeactivateMerchantModeUseCase _deactivateUseCase;
  final GetMerchantModeOriginUseCase _getOriginUseCase;

  MerchantModeController(
    this._checkUseCase,
    this._activateUseCase,
    this._deactivateUseCase,
    this._getOriginUseCase,
  ) : super(const AsyncValue.loading()) {
    checkStatus();
  }

  Future<void> checkStatus() async {
    state = const AsyncValue.loading();
    final result = await _checkUseCase();

    result.fold(
      (isActive) {
        state = AsyncValue.data(isActive);
      },
      (error) {
        state = AsyncValue.error(error, StackTrace.current);
      },
    );
  }

  Future<void> activate({String origin = '/home'}) async {
    final result = await _activateUseCase(origin: origin);

    result.fold(
      (_) {
        state = const AsyncValue.data(true);
      },
      (error) {
        state = AsyncValue.error(error, StackTrace.current);
      },
    );
  }

  Future<void> deactivate() async {
    final result = await _deactivateUseCase();

    result.fold(
      (_) {
        state = const AsyncValue.data(false);
      },
      (error) {
        state = AsyncValue.error(error, StackTrace.current);
      },
    );
  }

  Future<String> getOrigin() async {
    final result = await _getOriginUseCase();

    return result.fold((origin) => origin, (error) => '/home');
  }
}

final merchantModeControllerProvider =
    StateNotifierProvider<MerchantModeController, AsyncValue<bool>>((ref) {
      final checkUseCase = ref.watch(checkMerchantModeUseCaseProvider);
      final activateUseCase = ref.watch(activateMerchantModeUseCaseProvider);
      final deactivateUseCase = ref.watch(
        deactivateMerchantModeUseCaseProvider,
      );
      final getOriginUseCase = ref.watch(getMerchantModeOriginUseCaseProvider);

      return MerchantModeController(
        checkUseCase,
        activateUseCase,
        deactivateUseCase,
        getOriginUseCase,
      );
    });
