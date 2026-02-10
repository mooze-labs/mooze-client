import 'package:flutter_riverpod/flutter_riverpod.dart';

final transactionLoadingProvider = StateProvider<bool>((ref) => false);

class TransactionPreparationState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const TransactionPreparationState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  TransactionPreparationState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return TransactionPreparationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class TransactionPreparationController
    extends StateNotifier<TransactionPreparationState> {
  TransactionPreparationController()
    : super(const TransactionPreparationState());

  void startLoading() {
    state = const TransactionPreparationState(isLoading: true);
  }

  void setError(String error) {
    state = TransactionPreparationState(
      isLoading: false,
      errorMessage: error,
      isSuccess: false,
    );
  }

  void setSuccess() {
    state = const TransactionPreparationState(
      isLoading: false,
      errorMessage: null,
      isSuccess: true,
    );
  }

  void reset() {
    state = const TransactionPreparationState();
  }
}

final transactionPreparationControllerProvider = StateNotifierProvider<
  TransactionPreparationController,
  TransactionPreparationState
>((ref) {
  return TransactionPreparationController();
});
