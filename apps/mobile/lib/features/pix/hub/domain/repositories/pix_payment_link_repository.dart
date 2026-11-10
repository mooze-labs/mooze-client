import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_failure.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

/// The payment links of the user, through the Mooze payment-link API.
abstract class PixPaymentLinkRepository {
  /// Creates a link that charges [amountInCents] BRL cents and pays [asset]
  /// to [destinationAddress], a Liquid address of the wallet.
  ///
  /// Send the same [idempotencyKey] and the same inputs when you retry one
  /// charge. The API then returns the original link and creates no second one.
  TaskEither<PixHubFailure, PixPaymentLink> createFixedAmountLink({
    required int amountInCents,
    required Asset asset,
    required String destinationAddress,
    required bool singleUse,
    required String idempotencyKey,
  });

  /// Creates a link like [createFixedAmountLink]. A null [amountInCents]
  /// lets the payer choose the amount.
  ///
  /// The API accepts an open amount only while the server enables it, and
  /// answers an error otherwise.
  TaskEither<PixHubFailure, PixPaymentLink> createLink({
    int? amountInCents,
    required Asset asset,
    required String destinationAddress,
    required bool singleUse,
    required String idempotencyKey,
  });

  /// Lists the links of the user, newest first. The references are empty:
  /// the API does not store them.
  TaskEither<PixHubFailure, List<PixPaymentLink>> listLinks();

  /// Turns the link [id] off. A second call has no further effect.
  TaskEither<PixHubFailure, Unit> revokeLink(String id);
}
