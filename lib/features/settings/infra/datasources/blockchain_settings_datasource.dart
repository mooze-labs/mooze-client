import 'package:mooze_mobile/shared/utils/result.dart';

/// Blockchain Settings Data Source Contract (Infrastructure Layer)
abstract class BlockchainSettingsDataSource {
  /// Persists the node URL
  Future<Result<void>> setNodeUrl(String url);

  /// Retrieves the stored node URL
  Future<Result<String>> getNodeUrl();
}
