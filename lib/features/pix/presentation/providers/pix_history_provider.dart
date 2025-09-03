import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/database/database.dart';
import 'package:mooze_mobile/features/pix/data/datasources/pix_deposit_db.dart';
import 'package:mooze_mobile/features/pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/infra/db/providers/app_database_provider.dart';

// Provider for PixDepositDatabase
final pixDepositDatabaseProvider = Provider<PixDepositDatabase>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return PixDepositDatabase(database);
});

// Provider for PIX deposit history
final pixDepositHistoryProvider =
    FutureProvider<Either<String, List<PixDeposit>>>((ref) async {
      final pixDb = ref.watch(pixDepositDatabaseProvider);

      final result = await pixDb.getAllDeposits().run();

      return result.map((deposits) {
        return deposits
            .map((deposit) => _mapDepositToPixDeposit(deposit))
            .toList();
      });
    });

// Provider for specific PIX deposit
final pixDepositProvider =
    FutureProvider.family<Either<String, Option<PixDeposit>>, String>((
      ref,
      depositId,
    ) async {
      final pixDb = ref.watch(pixDepositDatabaseProvider);

      final result = await pixDb.getDeposit(depositId).run();

      return result.map((optionalDeposit) {
        return optionalDeposit.map(_mapDepositToPixDeposit);
      });
    });

PixDeposit _mapDepositToPixDeposit(Deposit deposit) {
  final asset = Asset.values.firstWhere(
    (a) => a.id == deposit.assetId,
    orElse: () => Asset.btc,
  );

  DepositStatus status;
  switch (deposit.status) {
    case 'pending':
      status = DepositStatus.pending;
      break;
    case 'processing':
      status = DepositStatus.processing;
      break;
    case 'finished':
      status = DepositStatus.finished;
      break;
    case 'expired':
      status = DepositStatus.expired;
      break;
    default:
      status = DepositStatus.pending;
  }

  return PixDeposit(
    depositId: deposit.depositId,
    pixKey: deposit.pixKey,
    asset: asset,
    amountInCents: deposit.amountInCents,
    network: 'PIX',
    status: status,
    createdAt: deposit.createdAt,
    blockchainTxid: deposit.blockchainTxid,
    assetAmount: deposit.assetAmount,
  );
}
