import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/shared/entities/asset.dart';

import '../entities.dart';

abstract class SwapWallet {
  TaskEither<String, List<SwapUtxo>> getUtxos(Asset asset, BigInt amount);
  Task<String> getAddress();
  TaskEither<String, String> signSwapOperation(String pset);
}
