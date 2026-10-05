import 'package:shared_preferences/shared_preferences.dart';
import 'package:mooze_mobile/features/settings/infra/datasources/node_fallback_datasource.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

/// Node Fallback Local Data Source (External Layer)
///
/// Single global flag persisted under key 'custom_fallback_enabled'.
/// Defaults to true so existing behavior (custom URL with no fallback,
/// because the BDK provider previously just used the custom URL alone)
/// remains identical until the user explicitly toggles it off.
class NodeFallbackLocalDataSource implements NodeFallbackDataSource {
  static const String storageKey = 'custom_fallback_enabled';
  static const bool defaultEnabled = true;

  @override
  Future<Result<bool>> getCustomFallbackEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return Success(prefs.getBool(storageKey) ?? defaultEnabled);
    } catch (e) {
      return Failure(
        'Erro ao obter a configuração de fallback: ${e.toString()}',
        e as Exception?,
      );
    }
  }

  @override
  Future<Result<void>> setCustomFallbackEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(storageKey, enabled);
      return const Success(null);
    } catch (e) {
      return Failure(
        'Erro ao salvar a configuração de fallback: ${e.toString()}',
        e as Exception?,
      );
    }
  }
}
