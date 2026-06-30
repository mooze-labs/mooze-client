import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/features/pix/receive_pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/pix_deposit_controller_provider.dart';

final depositDataProvider = FutureProvider.autoDispose
    .family<Either<String, PixDeposit>, String>((ref, depositId) async {
  final controller = await ref.read(pixDepositControllerProvider.future);
  final result = await controller.getDeposit(depositId).run();
  return result.fold(
    (err) => left(err),
    (deposit) => right(deposit),
  );
});
