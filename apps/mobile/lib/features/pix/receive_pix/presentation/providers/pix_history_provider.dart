import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/receive_pix/di/providers/pix_repository_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/controllers/pix_history_controller.dart';

final pixHistoryControllerProvider = Provider<PixHistoryController>((ref) {
  return PixHistoryController(ref.watch(pixRepositoryProvider));
});
