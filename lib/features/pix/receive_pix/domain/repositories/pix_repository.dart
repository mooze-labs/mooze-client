import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/features/pix/receive_pix/domain/entities/pix_deposit.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/features/pix/receive_pix/data/models/pix_status_event.dart';

abstract class PixRepository {
  Stream<PixStatusEvent> get statusUpdates;

  TaskEither<String, PixDeposit> newDeposit(
    int amountInCents,
    String address, {
    Asset asset = Asset.depix,
    String network = "liquid",
  });
  TaskEither<String, Option<PixDeposit>> getDeposit(String depositId);
  TaskEither<String, List<PixDeposit>> getDeposits({int? limit, int? offset});
  TaskEither<String, List<PixDeposit>> updateDepositDetails(
    List<String> depositIds,
  );
}
