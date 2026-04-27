import 'package:mooze_mobile/features/settings/domain/repositories/node_fallback_repository.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

class GetCustomFallbackEnabledUseCase {
  final NodeFallbackRepository _repository;

  const GetCustomFallbackEnabledUseCase(this._repository);

  Future<Result<bool>> call() async {
    return await _repository.getCustomFallbackEnabled();
  }
}
