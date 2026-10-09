import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/analytics/providers.dart';
import 'package:mooze_mobile/features/pix/receive_pix/di/providers/pix_repository_provider.dart';

import '../controllers/pix_deposit_controller.dart';

final pixDepositControllerProvider =
    FutureProvider.autoDispose<PixDepositController>((ref) async {
      final analytics = ref.read(analyticsProvider);
      final tracker = ref.read(pixAnalyticsProvider);
      return PixDepositController(
        ref.read(pixRepositoryProvider),
        track: analytics.track,
        observe: (deposit) =>
            tracker.observe(deposit.depositId, deposit.status.name),
      );
    });
