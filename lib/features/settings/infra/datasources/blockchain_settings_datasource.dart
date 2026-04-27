import 'package:mooze_mobile/shared/utils/result.dart';

/// Blockchain Settings Data Source Contract (Infrastructure Layer)
abstract class BlockchainSettingsDataSource {
  /// Persists the node URL
  Future<Result<void>> setNodeUrl(String url);

  /// Retrieves the stored node URL. Returns an empty string when no
  /// custom URL is persisted.
  Future<Result<String>> getNodeUrl();

  /// Removes the persisted node URL, restoring default behavior.
  Future<Result<void>> clearNodeUrl();
}
