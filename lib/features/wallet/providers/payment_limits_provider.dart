import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/payment_limits.dart';
import '../di/providers/wallet_repository_provider.dart';

final lightningLimitsProvider = FutureProvider<LightningPaymentLimitsResponse?>(
  (ref) async {
    final walletRepositoryEither = await ref.read(
      walletRepositoryProvider.future,
    );

    return await walletRepositoryEither.fold((error) async => null, (
      walletRepository,
    ) async {
      final result = await walletRepository.fetchLightningLimits().run();
      return result.fold((error) => null, (limits) => limits);
    });
  },
);

final lightningSendLimitsProvider = FutureProvider<PaymentLimits?>((ref) async {
  final lightningLimits = await ref.watch(lightningLimitsProvider.future);
  return lightningLimits?.send;
});

final paymentLimitsSummaryProvider = FutureProvider<PaymentLimits?>((
  ref,
) async {
  final lightningLimits = await ref.watch(lightningLimitsProvider.future);

  BigInt? minSat;
  BigInt? maxSat;

  if (lightningLimits != null) {
    if (minSat == null || lightningLimits.send.minSat < minSat) {
      minSat = lightningLimits.send.minSat;
    }
    if (maxSat == null || lightningLimits.send.maxSat > maxSat) {
      maxSat = lightningLimits.send.maxSat;
    }
  }

  if (minSat != null && maxSat != null) {
    return PaymentLimits(minSat: minSat, maxSat: maxSat);
  }

  return null;
});
