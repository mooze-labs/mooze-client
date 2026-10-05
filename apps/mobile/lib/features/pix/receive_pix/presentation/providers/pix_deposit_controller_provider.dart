import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/receive_pix/di/providers/pix_repository_provider.dart';

import '../controllers/pix_deposit_controller.dart';

final pixDepositControllerProvider =
    FutureProvider.autoDispose<PixDepositController>((ref) async {
  return PixDepositController(ref.read(pixRepositoryProvider));
});
