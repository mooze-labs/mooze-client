import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domains/repositories/blockchain_settings_repository.dart';

class BitcoinSettingsRepository extends BlockchainSettingsRepository {
  @override
  TaskEither<String, Unit> setNodeUrl(String url) {
    return TaskEither.tryCatch(() async {
      final sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.setString('bitcoin_node_url', url);
      return unit;
    }, (error, stackTrace) => 'Erro ao atualizar a URL do node: $error');
  }

  @override
  TaskEither<String, String> getNodeUrl() {
    return TaskEither.tryCatch(() async {
      final sharedPreferences = await SharedPreferences.getInstance();
      return sharedPreferences.getString('bitcoin_node_url') ?? '';
    }, (error, stackTrace) => 'Erro ao obter a URL do node: $error');
  }
}
