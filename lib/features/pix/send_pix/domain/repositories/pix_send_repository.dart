import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/send_pix/domain/entities/send_entities.dart';

abstract class IPixSendRepository {
  TaskEither<String, PixPaymentRequest> createPixPayment(String pixKeyOrCode);
  TaskEither<String, PixPayment> confirmPixPayment(String invoice);
  TaskEither<String, WithdrawStatus> getWithdrawStatus(String withdrawId);
}
