import 'package:shared_preferences/shared_preferences.dart';
import 'package:mooze_mobile/features/settings/infra/datasources/blockchain_settings_datasource.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

/// Liquid Settings Local Data Source Implementation (External Layer)
///
/// Storage Key: 'liquid_node_url'
/// Default: 'blockstream.info:465'
class LiquidSettingsLocalDataSource implements BlockchainSettingsDataSource {
  static const String _key = 'liquid_node_url';
  static const String _defaultUrl = 'blockstream.info:465';

  @override
  Future<Result<void>> setNodeUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, url);
      return const Success(null);
    } catch (e) {
      return Failure(
        'Erro ao atualizar a URL do node: ${e.toString()}',
        e as Exception?,
      );
    }
  }

  @override
  Future<Result<String>> getNodeUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return Success(prefs.getString(_key) ?? _defaultUrl);
    } catch (e) {
      return Failure(
        'Erro ao obter a URL do node: ${e.toString()}',
        e as Exception?,
      );
    }
  }
}
