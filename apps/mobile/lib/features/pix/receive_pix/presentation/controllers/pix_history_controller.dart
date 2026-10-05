import 'package:fpdart/fpdart.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/features/pix/receive_pix/domain/repositories/pix_repository.dart';

class PixHistoryController {
  final PixRepository _repo;

  PixHistoryController(PixRepository repo) : _repo = repo;

  /// History page. The core refreshes the non-terminal deposits from the
  /// backend and falls back to the local data when the refresh fails.
  TaskEither<String, List<PixDeposit>> getPixHistory({
    int? limit,
    int? offset,
  }) {
    return _repo.getHistory(limit: limit, offset: offset);
  }

  TaskEither<String, Option<PixDeposit>> getPixDeposit(String depositId) {
    return _repo.getDeposit(depositId);
  }
}
