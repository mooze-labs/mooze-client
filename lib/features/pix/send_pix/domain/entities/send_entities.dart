import 'package:freezed_annotation/freezed_annotation.dart';

part 'send_entities.freezed.dart';
part 'send_entities.g.dart';

@freezed
sealed class PixPaymentQuote with _$PixPaymentQuote {
  const factory PixPaymentQuote({
    required int satoshis,
    required double btcToBrlRate,
    required int brlAmount,
  }) = _PixPaymentQuote;

  factory PixPaymentQuote.fromJson(Map<String, dynamic> json) =>
      _$PixPaymentQuoteFromJson(json);
}

@freezed
sealed class PixPaymentRequest with _$PixPaymentRequest {
  const factory PixPaymentRequest({
    required bool success,
    required String invoice,
    required int valueInSatoshis,
    required String pixKey,
    required String qrCode,
    required int valueInBrl,
    required int fee,
    required PixPaymentQuote quote,
  }) = _PixPaymentRequest;

  factory PixPaymentRequest.fromJson(Map<String, dynamic> json) =>
      _$PixPaymentRequestFromJson(json);
}

@freezed
sealed class WithdrawStatus with _$WithdrawStatus {
  const factory WithdrawStatus({
    required String status, // 'pending', 'processing', 'completed', 'failed'
    required String withdrawId,
    String? txid,
    String? errorMessage,
    DateTime? completedAt,
  }) = _WithdrawStatus;

  factory WithdrawStatus.fromJson(Map<String, dynamic> json) =>
      _$WithdrawStatusFromJson(json);
}

@freezed
sealed class PixPayment with _$PixPayment {
  const factory PixPayment({
    required String withdrawId,
    required String invoice,
    required int valueInBrl,
    required int valueInSatoshis,
    required String pixKey,
    required int fee,
    required PixPaymentQuote quote,
    required DateTime createdAt,
  }) = _PixPayment;

  factory PixPayment.fromJson(Map<String, dynamic> json) =>
      _$PixPaymentFromJson(json);
}
