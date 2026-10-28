import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_failure.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link.dart';
import 'package:mooze_mobile/features/pix/hub/domain/repositories/pix_hub_repository.dart';

/// State of the payment-link form.
class PixPaymentLinkFormState {
  final PixPaymentLink? created;
  final bool isBusy;
  final PixHubFailure? failure;

  const PixPaymentLinkFormState({
    this.created,
    this.isBusy = false,
    this.failure,
  });
}

/// Creates payment links for the user.
class PixPaymentLinkFormController
    extends StateNotifier<PixPaymentLinkFormState> {
  final PixHubRepository _repository;

  PixPaymentLinkFormController(this._repository)
    : super(const PixPaymentLinkFormState());

  void reset() => state = const PixPaymentLinkFormState();

  /// Creates a link. Pass a null [amountInCents] for an open charge.
  Future<PixPaymentLink?> create({
    required String reference,
    required bool singleUse,
    int? amountInCents,
  }) async {
    state = const PixPaymentLinkFormState(isBusy: true);
    final result = await _repository
        .createPaymentLink(
          reference: reference,
          singleUse: singleUse,
          amountInCents: amountInCents,
        )
        .run();

    return result.fold(
      (failure) {
        state = PixPaymentLinkFormState(failure: failure);
        return null;
      },
      (link) {
        state = PixPaymentLinkFormState(created: link);
        return link;
      },
    );
  }
}
