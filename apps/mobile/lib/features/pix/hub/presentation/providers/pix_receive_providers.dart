import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/controllers/pix_payment_link_form_controller.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/controllers/pix_payment_request_controller.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_hub_providers.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/pix_history_provider.dart';

/// State of the charge-creation screen.
final pixPaymentRequestControllerProvider =
    StateNotifierProvider.autoDispose<
      PixPaymentRequestController,
      PixPaymentRequestState
    >(
      (ref) => PixPaymentRequestController(ref.watch(pixHubRepositoryProvider)),
    );

/// State of the payment-link form.
final pixPaymentLinkFormControllerProvider =
    StateNotifierProvider.autoDispose<
      PixPaymentLinkFormController,
      PixPaymentLinkFormState
    >(
      (ref) =>
          PixPaymentLinkFormController(ref.watch(pixHubRepositoryProvider)),
    );

/// The real deposits of the user, read from mooze-core.
///
/// The pending screen filters this list by status.
final pixDepositHistoryProvider =
    FutureProvider.autoDispose<Either<String, List<PixDeposit>>>(
      (ref) => ref.watch(pixHistoryControllerProvider).getPixHistory().run(),
    );
