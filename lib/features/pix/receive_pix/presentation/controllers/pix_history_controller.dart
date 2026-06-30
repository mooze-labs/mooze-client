import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/repositories/pix_repository.dart';

class PixHistoryController {
  final PixRepository _repo;

  PixHistoryController(PixRepository repo) : _repo = repo;

  TaskEither<String, List<PixDeposit>> getPixHistory({
    int? limit,
    int? offset,
  }) {
    return _repo.getDeposits(limit: limit, offset: offset).flatMap((deposits) {
      const terminalStatuses = {DepositStatus.expired, DepositStatus.refunded};

      final pendingDeposits =
          deposits
              .filter((t) => !terminalStatuses.contains(t.status))
              .map((d) => d.depositId)
              .toList();

      if (pendingDeposits.isEmpty) {
        return TaskEither.right(deposits);
      }

      return _repo
          .updateDepositDetails(pendingDeposits)
          .flatMap((_) {
            return _repo.getDeposits(limit: limit, offset: offset);
          })
          .orElse((error) {
            if (kDebugMode) {
              debugPrint(
                "[PixHistoryController] Error updating deposits: $error",
              );
            }
            return TaskEither.right(deposits);
          });
    });
  }

  TaskEither<String, Option<PixDeposit>> getPixDeposit(String depositId) {
    return _repo.getDeposit(depositId);
  }
}
