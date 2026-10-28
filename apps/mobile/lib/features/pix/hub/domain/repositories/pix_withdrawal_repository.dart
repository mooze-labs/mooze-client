import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_failure.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_withdrawal.dart';

/// Pix withdrawals of the Mooze backend (Pix2Depix, through Eulen).
///
/// Unlike [PixHubRepository], this contract calls the real backend.
abstract class PixWithdrawalRepository {
  /// Creates a withdrawal that pays [payoutAmountInCents] BRL cents to
  /// [pixKey].
  ///
  /// [taxId] is the CPF or CNPJ of the key owner. [refundAddress] is a Liquid
  /// address of the wallet: the provider returns failed or late deposits to it.
  ///
  /// The backend has no idempotency key for this call. A retry creates a new
  /// withdrawal. That is safe while no deposit was sent, because no funds move
  /// until the wallet funds one withdrawal.
  TaskEither<PixHubFailure, PixWithdrawal> create({
    required String pixKey,
    required int payoutAmountInCents,
    required String taxId,
    required String refundAddress,
  });

  /// Reads the status of the withdrawals [ids]. Unknown IDs are absent from
  /// the result.
  TaskEither<PixHubFailure, List<PixWithdrawalDetails>> statuses(
    List<String> ids,
  );
}
