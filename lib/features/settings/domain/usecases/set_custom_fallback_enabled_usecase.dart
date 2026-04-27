import 'package:mooze_mobile/features/settings/domain/repositories/node_fallback_repository.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

class SetCustomFallbackEnabledUseCase {
  final NodeFallbackRepository _repository;

  const SetCustomFallbackEnabledUseCase(this._repository);

  Future<Result<void>> call(bool enabled) async {
    return await _repository.setCustomFallbackEnabled(enabled);
  }
}
