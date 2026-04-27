import 'package:mooze_mobile/shared/utils/result.dart';

/// Node Fallback Data Source Contract (Infrastructure Layer)
abstract class NodeFallbackDataSource {
  Future<Result<bool>> getCustomFallbackEnabled();

  Future<Result<void>> setCustomFallbackEnabled(bool enabled);
}
