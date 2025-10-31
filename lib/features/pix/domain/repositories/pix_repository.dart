import 'package:fpdart/fpdart.dart';

import '../entities.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import '../../data/models/pix_status_event.dart';

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
