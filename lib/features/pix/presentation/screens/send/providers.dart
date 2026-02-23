import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/application/send_controller.dart';
import 'package:mooze_mobile/features/pix/data/mock_send_repository.dart';
import 'package:mooze_mobile/features/pix/domain/send_entities.dart';

// Repository provider
final pixSendRepositoryProvider = Provider((ref) => MockPixSendRepository());

// Controller provider
final pixSendControllerProvider = Provider((ref) {
  final repository = ref.watch(pixSendRepositoryProvider);
  return PixSendController(repository);
});

// State providers
final pixKeyInputProvider = StateProvider<String>((ref) => '');
final currentPixPaymentRequestProvider = StateProvider<PixPaymentRequest?>(
  (ref) => null,
);
final currentPixPaymentProvider = StateProvider<PixPayment?>((ref) => null);

// Async providers
final createPixPaymentProvider =
    FutureProvider.family<Either<String, PixPaymentRequest>, String>((
      ref,
      pixKeyOrCode,
    ) async {
      final controller = ref.watch(pixSendControllerProvider);
      return controller.createPixPayment(pixKeyOrCode).run();
    });

final withdrawStatusProvider =
    StreamProvider.family<Either<String, WithdrawStatus>, String>((
      ref,
      withdrawId,
    ) {
      final controller = ref.watch(pixSendControllerProvider);
      return controller.pollWithdrawStatus(withdrawId);
    });
