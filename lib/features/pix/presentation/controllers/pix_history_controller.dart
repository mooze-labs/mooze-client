import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/features/pix/domain/repositories/pix_repository.dart';
import 'package:mooze_mobile/features/pix/presentation/providers/pix_history_provider.dart';

class PixHistoryController {
  final PixRepository _repo;

  PixHistoryController(PixRepository repo) : _repo = repo;

  TaskEither<String, List<PixDeposit>> getPixHistory({
    int? limit,
    int? offset,
  }) {
    return _repo.getDeposits(limit: limit, offset: offset).flatMap((d) {
      final pendingDeposits =
          d
              .filter(
                (t) =>
                    ((t.status != DepositStatus.finished) &&
                        (t.status != DepositStatus.expired)),
              )
              .map((d) => d.depositId)
              .toList();

      return TaskEither.tryCatch(() async {
        if (pendingDeposits.isNotEmpty) {
          await _repo.updateDepositDetails(pendingDeposits).run();
        }
        return _repo.getDeposits(limit: limit, offset: offset);
      }, (error, _) => error.toString()).flatMap((task) => task);
    });
  }

  TaskEither<String, Option<PixDeposit>> getPixDeposit(String depositId) {
    return _repo.getDeposit(depositId);
  }
}
