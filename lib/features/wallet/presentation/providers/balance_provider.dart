import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/di/providers/wallet_repository_provider.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
import 'package:mooze_mobile/features/wallet/presentation/controllers/balance_controller.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

final balanceControllerProvider = FutureProvider<Either<WalletError, BalanceController>>((ref) async {
  final wallet = await ref.read(walletRepositoryProvider.future);
  return wallet.flatMap((w) => Either.right(BalanceController(w)));
});

final balanceProvider = FutureProvider.family<Either<WalletError, BigInt>, Asset>((
  ref,
  Asset asset,
) async {
  final controller = await ref.read(balanceControllerProvider.future);

  return controller.fold(
      (err) async => Either.left(err),
      (controller) async => controller.getAssetBalance(asset).run()
  );
});