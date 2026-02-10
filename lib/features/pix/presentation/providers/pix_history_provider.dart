import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/database/database.dart';
import 'package:mooze_mobile/features/pix/data/datasources/pix_deposit_db.dart';
import 'package:mooze_mobile/features/pix/di/providers/pix_repository_provider.dart';
import 'package:mooze_mobile/features/pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/features/pix/presentation/controllers/pix_history_controller.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/infra/db/providers/app_database_provider.dart';

// Provider for PixDepositDatabase
final pixDepositDatabaseProvider = Provider<PixDepositDatabase>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return PixDepositDatabase(database);
});

final pixHistoryControllerProvider = Provider<PixHistoryController>((ref) {
  final repository = ref.read(pixRepositoryProvider);
  final controller = PixHistoryController(repository);

  return controller;
});

final pixDepositHistoryProvider =
    FutureProvider.autoDispose<Either<String, List<PixDeposit>>>((ref) async {
      final controller = ref.read(pixHistoryControllerProvider);

      final deposits = await controller.getPixHistory().run();
      return deposits;
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
    case 'under_review':
      status = DepositStatus.underReview;
      break;
    case 'processing':
      status = DepositStatus.processing;
      break;
    case 'funds_prepared':
      status = DepositStatus.fundsPrepared;
      break;
    case 'depix_sent':
    case "paid":
      status = DepositStatus.depixSent;
      break;
    case 'broadcasted':
      status = DepositStatus.broadcasted;
      break;
    case 'finished':
      status = DepositStatus.finished;
      break;
    case 'failed':
      status = DepositStatus.failed;
      break;
    case 'refunded':
      status = DepositStatus.refunded;
      break;
    default:
      status = DepositStatus.unknown;
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
