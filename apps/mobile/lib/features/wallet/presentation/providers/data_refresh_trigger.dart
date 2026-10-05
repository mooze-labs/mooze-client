import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Drives stale-while-revalidate re-renders on the home/holdings widgets
/// without putting them into a `loading` state. Consumers `ref.watch` the
/// counter; producers (the V2 sync orchestrator's tx event pipeline or
/// any flow that fetched fresh data) call `triggerRefresh()` to bump it.
class DataRefreshNotifier extends StateNotifier<int> {
  DataRefreshNotifier() : super(0);

  void triggerRefresh() {
    state = state + 1;
  }
}

final dataRefreshTriggerProvider =
    StateNotifierProvider<DataRefreshNotifier, int>((ref) {
  return DataRefreshNotifier();
});
