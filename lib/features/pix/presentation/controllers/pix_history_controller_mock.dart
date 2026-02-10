import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/features/pix/presentation/providers/pix_history_provider_mock.dart';

class PixHistoryControllerMock
    extends StateNotifier<AsyncValue<List<PixDeposit>>> {
  final Ref _ref;

  PixHistoryControllerMock(this._ref) : super(const AsyncValue.loading()) {
    loadPixHistory();
  }

  Future<void> loadPixHistory() async {
    state = const AsyncValue.loading();

    final result = await _ref.read(pixDepositHistoryProviderMock.future);

    result.fold(
      (error) => state = AsyncValue.error(error, StackTrace.current),
      (deposits) => state = AsyncValue.data(deposits),
    );
  }

  Future<void> refreshPixHistory() async {
    _ref.invalidate(pixDepositHistoryProviderMock);
    await loadPixHistory();
  }

  Future<Either<String, PixDeposit?>> getPixDeposit(String depositId) async {
    final result = await _ref.read(pixDepositProviderMock(depositId).future);

    return result.map((option) => option.toNullable());
  }
}

final pixHistoryControllerProviderMock = StateNotifierProvider<
  PixHistoryControllerMock,
  AsyncValue<List<PixDeposit>>
>((ref) {
  return PixHistoryControllerMock(ref);
});
