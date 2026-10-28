import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_failure.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_key.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_request.dart';
import 'package:mooze_mobile/features/pix/hub/domain/repositories/pix_hub_repository.dart';

/// State of the charge-creation screen.
class PixPaymentRequestState {
  final PixPaymentRequest? request;
  final bool isBusy;
  final PixHubFailure? failure;

  const PixPaymentRequestState({
    this.request,
    this.isBusy = false,
    this.failure,
  });
}

/// Creates the charge another person pays.
class PixPaymentRequestController
    extends StateNotifier<PixPaymentRequestState> {
  final PixHubRepository _repository;

  PixPaymentRequestController(this._repository)
    : super(const PixPaymentRequestState());

  void reset() => state = const PixPaymentRequestState();

  /// Creates a charge for [key]. Pass a null [amountInCents] to let the payer
  /// inform the amount.
  Future<bool> create({
    required PixKey key,
    int? amountInCents,
    String? description,
  }) async {
    state = const PixPaymentRequestState(isBusy: true);
    final result = await _repository
        .createPaymentRequest(
          key: key,
          amountInCents: amountInCents,
          description: description,
        )
        .run();

    return result.fold(
      (failure) {
        state = PixPaymentRequestState(failure: failure);
        return false;
      },
      (request) {
        state = PixPaymentRequestState(request: request);
        return true;
      },
    );
  }
}
