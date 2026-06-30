import 'package:mooze_mobile/shared/utils/result.dart';

/// Blockchain Settings Repository Contract (Domain Layer)
///
/// Defines operations for persisting and retrieving
/// node URL configuration for a blockchain network.
abstract class BlockchainSettingsRepository {
  /// Persists the node URL for this blockchain network
  Future<Result<void>> setNodeUrl(String url);

  /// Retrieves the stored node URL for this blockchain network.
  /// Returns an empty string when no custom URL has been configured —
  /// callers should treat this as "default mode" (let the underlying
  /// infrastructure pick the server via its fallback list).
  Future<Result<String>> getNodeUrl();

  /// Removes any custom node URL, restoring the system default behavior.
  /// After calling this, [getNodeUrl] returns an empty string and the
  /// blockchain providers fall back to their built-in server rotation.
  Future<Result<void>> clearNodeUrl();
}
