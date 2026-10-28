import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_key.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_send_method.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_transaction.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_hub_failure.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_withdrawal.dart';
import 'package:mooze_mobile/features/pix/hub/domain/validation/pix_br_code.dart';
import 'package:mooze_mobile/features/pix/hub/domain/validation/pix_key_validator.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

/// Translations of the Pix hub enums.
///
/// Keeping the mapping here stops each screen from repeating the same switch.

String pixKeyTypeLabel(AppLocalizations t, PixKeyType type) {
  return switch (type) {
    PixKeyType.cpf => t.pix_hub_key_type_cpf,
    PixKeyType.cnpj => t.pix_hub_key_type_cnpj,
    PixKeyType.phone => t.pix_hub_key_type_phone,
    PixKeyType.email => t.pix_hub_key_type_email,
    PixKeyType.random => t.pix_hub_key_type_random,
  };
}

String pixTransactionKindLabel(AppLocalizations t, PixTransactionKind kind) {
  return switch (kind) {
    PixTransactionKind.sent => t.pix_hub_tx_kind_sent,
    PixTransactionKind.received => t.pix_hub_tx_kind_received,
    PixTransactionKind.deposit => t.pix_hub_tx_kind_deposit,
    PixTransactionKind.paymentLink => t.pix_hub_tx_kind_payment_link,
  };
}

String pixTransactionStatusLabel(
  AppLocalizations t,
  PixTransactionStatus status,
) {
  return switch (status) {
    PixTransactionStatus.completed => t.pix_hub_tx_status_completed,
    PixTransactionStatus.pending => t.pix_hub_tx_status_pending,
    PixTransactionStatus.failed => t.pix_hub_tx_status_failed,
  };
}

String pixSendMethodLabel(AppLocalizations t, PixSendMethod method) {
  return switch (method) {
    PixSendMethod.key => t.pix_hub_method_key,
    PixSendMethod.qrCode => t.pix_hub_method_qr,
    PixSendMethod.copyPaste => t.pix_hub_method_copy_paste,
    PixSendMethod.recent => t.pix_hub_method_recent,
  };
}

String pixPaymentLinkStatusLabel(
  AppLocalizations t,
  PixPaymentLinkStatus status,
) {
  return switch (status) {
    PixPaymentLinkStatus.pending => t.pix_hub_link_status_pending,
    PixPaymentLinkStatus.paid => t.pix_hub_link_status_paid,
    PixPaymentLinkStatus.expired => t.pix_hub_link_status_expired,
  };
}

String pixKeyValidationMessage(
  AppLocalizations t,
  PixKeyValidationError error,
) {
  return switch (error) {
    PixKeyValidationError.empty => t.pix_hub_key_error_empty,
    PixKeyValidationError.unrecognized => t.pix_hub_key_error_unrecognized,
    PixKeyValidationError.invalidDocument => t.pix_hub_key_error_document,
    PixKeyValidationError.invalidPhone => t.pix_hub_key_error_phone,
    PixKeyValidationError.invalidEmail => t.pix_hub_key_error_email,
    PixKeyValidationError.invalidRandomKey => t.pix_hub_key_error_random,
  };
}

String pixBrCodeErrorMessage(AppLocalizations t, PixBrCodeError error) {
  return switch (error) {
    PixBrCodeError.empty => t.pix_hub_code_error_empty,
    PixBrCodeError.tooShort => t.pix_hub_code_error_short,
    PixBrCodeError.malformed => t.pix_hub_code_error_malformed,
    PixBrCodeError.notPix => t.pix_hub_code_error_not_pix,
    PixBrCodeError.invalidChecksum => t.pix_hub_code_error_checksum,
  };
}

String pixHubFailureMessage(AppLocalizations t, PixHubFailure failure) {
  return switch (failure.code) {
    PixHubErrorCode.loadFailed => t.pix_hub_failure_load,
    PixHubErrorCode.paymentDeclined => t.pix_hub_failure_declined,
    PixHubErrorCode.recipientNotFound => t.pix_hub_failure_recipient,
    PixHubErrorCode.amountOutOfBounds => t.pix_hub_failure_amount,
    PixHubErrorCode.network => t.pix_hub_failure_network,
    PixHubErrorCode.sessionUnavailable => t.pix_hub_failure_session,
    PixHubErrorCode.notEligible => t.pix_hub_failure_not_eligible,
    PixHubErrorCode.rateLimited => t.pix_hub_failure_rate_limited,
    PixHubErrorCode.serviceUnavailable => t.pix_hub_failure_unavailable,
    PixHubErrorCode.invalidResponse => t.pix_hub_failure_invalid_response,
    PixHubErrorCode.walletUnavailable => t.pix_hub_failure_wallet,
    PixHubErrorCode.invalidRequest => t.pix_hub_failure_invalid_request,
    PixHubErrorCode.limitExceeded => t.pix_hub_failure_limit_exceeded,
    PixHubErrorCode.providerRefused => t.pix_hub_failure_provider_refused,
    PixHubErrorCode.outcomeUnknown => t.pix_hub_failure_outcome_unknown,
    PixHubErrorCode.quoteMismatch => t.pix_hub_failure_quote_mismatch,
    PixHubErrorCode.quoteExpired => t.pix_hub_failure_quote_expired,
    PixHubErrorCode.insufficientFunds => t.pix_hub_failure_insufficient_funds,
    PixHubErrorCode.insufficientFeeAsset =>
      t.pix_hub_failure_insufficient_fee_asset,
    PixHubErrorCode.fundingFailed => t.pix_hub_failure_funding_failed,
    PixHubErrorCode.unsupportedCode => t.pix_hub_failure_unsupported_code,
    PixHubErrorCode.unknown => t.pix_hub_failure_unknown,
  };
}

/// Label of a withdrawal status. Null means that no status was read yet.
String pixWithdrawalStatusLabel(
  AppLocalizations t,
  PixWithdrawalStatus? status,
) {
  return switch (status) {
    null => t.pix_hub_withdrawal_status_checking,
    PixWithdrawalStatus.creating => t.pix_hub_withdrawal_status_creating,
    PixWithdrawalStatus.rejected => t.pix_hub_withdrawal_status_rejected,
    PixWithdrawalStatus.uncertain => t.pix_hub_withdrawal_status_uncertain,
    PixWithdrawalStatus.unsent => t.pix_hub_withdrawal_status_unsent,
    PixWithdrawalStatus.sending => t.pix_hub_withdrawal_status_sending,
    PixWithdrawalStatus.sent => t.pix_hub_withdrawal_status_sent,
    PixWithdrawalStatus.error => t.pix_hub_withdrawal_status_error,
    PixWithdrawalStatus.canceled => t.pix_hub_withdrawal_status_canceled,
    PixWithdrawalStatus.refunded => t.pix_hub_withdrawal_status_refunded,
    PixWithdrawalStatus.replaced => t.pix_hub_withdrawal_status_replaced,
    PixWithdrawalStatus.unknown => t.pix_hub_withdrawal_status_unknown,
  };
}
