import 'package:fpdart/fpdart.dart';

abstract class BlockchainSettingsRepository {
  TaskEither<String, Unit> setNodeUrl(String url);
  TaskEither<String, String> getNodeUrl();
}
