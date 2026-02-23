import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/data/send_repository.dart';
import 'package:mooze_mobile/features/pix/domain/send_entities.dart';

class MockPixSendRepository implements IPixSendRepository {
  @override
  TaskEither<String, PixPaymentRequest> createPixPayment(String pixKeyOrCode) {
    return TaskEither.tryCatch(() async {
      // TODO: Integrate with the real API
      await Future.delayed(const Duration(seconds: 2));

      // Mock data
      return PixPaymentRequest(
        success: true,
        invoice:
            'lnbc100n1p3xqzyqpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdqqcqzpgsp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygs9q2gqqqqqyssqrzjqw8c7yfutqqy3kz8662fxutjvef7q2ujsxtt45csu0k688lkzu3ldqqqqryqqqqthqqpyrzjqw8c7yfutqqy3kz8662fxutjvef7q2ujsxtt45csu0k688lkzu3ldqqqqryqqqqthqqpysp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygq9qrsgqrzjqw8c7yfutqqy3kz8662fxutjvef7q2ujsxtt45csu0k688lkzu3ldqqqqryqqqqthqqpyrzjqw8c7yfutqqy3kz8662fxutjvef7q2ujsxtt45csu0k688lkzu3ldqqqqryqqqqthqqpysp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygs9q2gqqqqqyssqrzjqw8c7yfutqqy3kz8662fxutjvef7q2ujsxtt45csu0k688lkzu3ld',
        valueInSatoshis: 15000,
        pixKey: pixKeyOrCode,
        qrCode: pixKeyOrCode,
        valueInBrl: 1000, // 10 reais in cents
        fee: 50, // 0.50 cents
        quote: PixPaymentQuote(
          satoshis: 15000,
          btcToBrlRate: 650000.0,
          brlAmount: 1000,
        ),
      );
    }, (error, stackTrace) => 'Error creating PIX payment: $error');
  }

  @override
  TaskEither<String, PixPayment> confirmPixPayment(String invoice) {
    return TaskEither.tryCatch(() async {
      // TODO: Integrate with Breez SDK to pay the invoice
      await Future.delayed(const Duration(seconds: 2));

      return PixPayment(
        withdrawId: 'withdraw_${DateTime.now().millisecondsSinceEpoch}',
        invoice: invoice,
        valueInBrl: 1000,
        valueInSatoshis: 15000,
        pixKey: 'mock@pix.com',
        fee: 50,
        quote: PixPaymentQuote(
          satoshis: 15000,
          btcToBrlRate: 650000.0,
          brlAmount: 1000,
        ),
        createdAt: DateTime.now(),
      );
    }, (error, stackTrace) => 'Error confirming payment: $error');
  }

  @override
  TaskEither<String, WithdrawStatus> getWithdrawStatus(String withdrawId) {
    return TaskEither.tryCatch(() async {
      // TODO: Integrate with the real API
      await Future.delayed(const Duration(seconds: 1));

      // Mock: simulate payment progress
      final random = DateTime.now().second % 3;

      if (random == 0) {
        return WithdrawStatus(
          status: 'completed',
          withdrawId: withdrawId,
          txid: 'mock_txid_${DateTime.now().millisecondsSinceEpoch}',
          completedAt: DateTime.now(),
        );
      } else {
        return WithdrawStatus(status: 'processing', withdrawId: withdrawId);
      }
    }, (error, stackTrace) => 'Error checking status: $error');
  }
}
