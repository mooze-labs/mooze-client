import 'package:mooze_mobile/shared/utils/result.dart';

/// Blockchain Settings Repository Contract (Domain Layer)
///
/// Defines operations for persisting and retrieving
/// node URL configuration for a blockchain network.
abstract class BlockchainSettingsRepository {
  /// Persists the node URL for this blockchain network
  Future<Result<void>> setNodeUrl(String url);

  /// Retrieves the stored node URL for this blockchain network
  Future<Result<String>> getNodeUrl();
}
