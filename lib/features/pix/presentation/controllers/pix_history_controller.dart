import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/features/pix/domain/repositories/pix_repository.dart';

class PixHistoryController {
  final PixRepository _repo;

  PixHistoryController(PixRepository repo) : _repo = repo;

  TaskEither<String, List<PixDeposit>> getPixHistory({
    int? limit,
    int? offset,
  }) {
    return _repo.getDeposits(limit: limit, offset: offset).flatMap((deposits) {
      final pendingDeposits =
          deposits
              .filter(
                (t) =>
                    t.status != DepositStatus.finished &&
                    t.status != DepositStatus.failed,
              )
              .map((d) => d.depositId)
              .toList();

      if (pendingDeposits.isNotEmpty) {
        _repo
            .updateDepositDetails(pendingDeposits)
            .run()
            .then(
              (result) => result.fold(
                (error) {
                  if (kDebugMode) {
                    debugPrint(
                      "[PixHistoryController] Error updating deposits: $error",
                    );
                  }
                },
                (updatedDeposits) {
                  if (kDebugMode) {
                    debugPrint(
                      "[PixHistoryController] ${updatedDeposits.length} deposits updated successfully",
                    );
                  }
                },
              ),
            );
      }

      return TaskEither.right(deposits);
    });
  }

  TaskEither<String, Option<PixDeposit>> getPixDeposit(String depositId) {
    return _repo.getDeposit(depositId);
  }
}
