import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/domain/send_entities.dart';

abstract class IPixSendRepository {
  TaskEither<String, PixPaymentRequest> createPixPayment(String pixKeyOrCode);
  TaskEither<String, PixPayment> confirmPixPayment(String invoice);
  TaskEither<String, WithdrawStatus> getWithdrawStatus(String withdrawId);
}
