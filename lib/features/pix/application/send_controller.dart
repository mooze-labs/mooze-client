import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/data/send_repository.dart';
import 'package:mooze_mobile/features/pix/domain/send_entities.dart';

class PixSendController {
  final IPixSendRepository _repository;

  PixSendController(this._repository);

  TaskEither<String, PixPaymentRequest> createPixPayment(String pixKeyOrCode) {
    return _repository.createPixPayment(pixKeyOrCode);
  }

  TaskEither<String, PixPayment> confirmPayment(String invoice) {
    return _repository.confirmPixPayment(invoice);
  }

  TaskEither<String, WithdrawStatus> checkWithdrawStatus(String withdrawId) {
    return _repository.getWithdrawStatus(withdrawId);
  }

  // Polling helper
  Stream<Either<String, WithdrawStatus>> pollWithdrawStatus(
    String withdrawId, {
    Duration interval = const Duration(seconds: 3),
    int maxAttempts = 60,
  }) async* {
    int attempts = 0;

    while (attempts < maxAttempts) {
      final result = await checkWithdrawStatus(withdrawId).run();

      yield result;

      if (result.isRight()) {
        final status = result.getOrElse((l) => throw Exception(l));
        if (status.status == 'completed' || status.status == 'failed') {
          break;
        }
      }

      attempts++;
      await Future.delayed(interval);
    }
  }
}
