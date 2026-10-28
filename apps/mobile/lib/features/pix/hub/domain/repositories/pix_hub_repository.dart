import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_failure.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_overview.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_key.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_request.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_recipient.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_transaction.dart';

/// Data source of the Pix hub screens.
///
/// The only implementation today is the demonstration repository. Mooze has no
/// key registry or recipient lookup service, so every method here answers from
/// fictional data until such services exist. Sending uses
/// [PixWithdrawalRepository] instead.
abstract class PixHubRepository {
  /// Reads the sections of the hub home screen.
  TaskEither<PixHubFailure, PixHubOverview> loadOverview();

  /// Lists the Pix keys shown by the receive and key management screens.
  TaskEither<PixHubFailure, List<PixKey>> listKeys();

  /// Lists the recipients paid recently.
  TaskEither<PixHubFailure, List<PixRecipient>> listRecentRecipients();

  /// Lists Pix movements, newest first.
  TaskEither<PixHubFailure, List<PixTransaction>> listTransactions();

  /// Creates a charge so another person can pay the user.
  TaskEither<PixHubFailure, PixPaymentRequest> createPaymentRequest({
    required PixKey key,
    int? amountInCents,
    String? description,
  });

  /// Lists the payment links owned by the user.
  TaskEither<PixHubFailure, List<PixPaymentLink>> listPaymentLinks();

  /// Creates a payment link.
  TaskEither<PixHubFailure, PixPaymentLink> createPaymentLink({
    required String reference,
    required bool singleUse,
    int? amountInCents,
  });

  /// Removes the payment link [id] from the user's list.
  TaskEither<PixHubFailure, Unit> deletePaymentLink(String id);
}
