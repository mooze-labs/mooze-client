import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/features/pix/receive_pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/features/pix/receive_pix/data/models/pix_status_event.dart';

abstract class PixRepository {
  /// Status changes of the deposits created in this session, plus one
  /// `pending` event for each new deposit.
  Stream<PixStatusEvent> get statusUpdates;

  /// Creates a deposit. A null [address] pays to a new address of the
  /// Liquid wallet.
  TaskEither<String, PixDeposit> newDeposit(
    int amountInCents, {
    String? address,
    Asset asset = Asset.depix,
    String? taxIdNumber,
  });
  TaskEither<String, Option<PixDeposit>> getDeposit(String depositId);
  TaskEither<String, List<PixDeposit>> getDeposits({int? limit, int? offset});
  TaskEither<String, List<PixDeposit>> updateDepositDetails(
    List<String> depositIds,
  );

  /// History page: stored deposits, after a backend refresh of the
  /// non-terminal ones. A failed refresh returns the local data.
  TaskEither<String, List<PixDeposit>> getHistory({int? limit, int? offset});

  void dispose();
}
