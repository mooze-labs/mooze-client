import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_failure.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

/// Creates payment links through the Mooze payment-link API.
///
/// Unlike [PixHubRepository], this contract calls the real backend.
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
}
