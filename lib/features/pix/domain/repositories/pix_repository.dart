import 'package:fpdart/fpdart.dart';

import '../entities.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

abstract class PixRepository {
  TaskEither<String, PixDeposit> newDeposit(
    int amountInCents,
    String address, {
    Asset asset = Asset.depix,
    String network = "liquid",
  });
  TaskEither<String, Option<PixDeposit>> getDeposit(String depositId);
  TaskEither<String, List<PixDeposit>> getAllDeposits();
}
