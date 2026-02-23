import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/prices/settings/price_settings_repository.dart';

final isVisibleProvider = StateNotifierProvider<VisibilityNotifier, bool>((
  ref,
) {
  return VisibilityNotifier();
});

class VisibilityNotifier extends StateNotifier<bool> {
  VisibilityNotifier() : super(true) {
    _loadVisibility();
  }

  final _repo = PriceSettingsRepositoryImpl();

  Future<void> _loadVisibility() async {
    final result = await _repo.getBalanceVisibility().run();
    result.match((err) => state = true, (isVisible) => state = isVisible);
  }

  Future<void> setVisibility(bool isVisible) async {
    state = isVisible;
    final result = await _repo.setBalanceVisibility(isVisible).run();
    result.match((err) => null, (_) => null);
  }

  void toggle() {
    setVisibility(!state);
  }
}
