import 'package:fpdart/fpdart.dart';

enum BlockchainNetwork { bitcoin, liquid }

abstract class BlockchainSettingsRepository {
  TaskEither<String, Unit> setNodeUrl(String url);
  TaskEither<String, String> getNodeUrl();
}
