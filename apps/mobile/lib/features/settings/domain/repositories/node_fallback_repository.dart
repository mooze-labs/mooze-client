import 'package:mooze_mobile/shared/utils/result.dart';

/// Node Fallback Repository Contract (Domain Layer)
///
/// Stores a single global flag that controls whether the blockchain
/// providers should fall back to the built-in server list when a
/// user-configured custom node fails. Has no effect in default mode.
abstract class NodeFallbackRepository {
  /// Returns true when automatic fallback is enabled.
  /// Defaults to true when no value has been persisted.
  Future<Result<bool>> getCustomFallbackEnabled();

  /// Persists the custom-mode fallback flag.
  Future<Result<void>> setCustomFallbackEnabled(bool enabled);
}
