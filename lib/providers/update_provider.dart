import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/services/update_service.dart';

final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService();
});

class UpdateState {
  final bool hasUpdate;
  final String? newVersion;
  final String? localVersion;
  final bool isLoading;
  final String? error;

  const UpdateState({
    this.hasUpdate = false,
    this.newVersion,
    this.localVersion,
    this.isLoading = false,
    this.error,
  });

  UpdateState copyWith({
    bool? hasUpdate,
    String? newVersion,
    String? localVersion,
    bool? isLoading,
    String? error,
  }) {
    return UpdateState(
      hasUpdate: hasUpdate ?? this.hasUpdate,
      newVersion: newVersion ?? this.newVersion,
      localVersion: localVersion ?? this.localVersion,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class UpdateNotifier extends StateNotifier<UpdateState> {
  final UpdateService _updateService;

  UpdateNotifier(this._updateService) : super(const UpdateState());

  Future<void> checkForUpdates() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await Future.wait([
        _updateService.getUpdateData(),
        _updateService.getCurrentVersion(),
      ]);
      final updateData = results[0] as UpdateData;
      final localVersion = results[1] as String;
      final hasUpdate = _isNewerVersion(
        updateData.currentVersion,
        localVersion,
      );

      state = state.copyWith(
        hasUpdate: hasUpdate,
        newVersion: hasUpdate ? updateData.currentVersion : null,
        localVersion: localVersion,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void dismissUpdate() {
    state = state.copyWith(hasUpdate: false, newVersion: null);
  }

  bool _isNewerVersion(String remoteVersion, String currentVersion) {
    final remoteParts = _parseVersion(remoteVersion);
    final currentParts = _parseVersion(currentVersion);

    for (int i = 0; i < 3; i++) {
      if (remoteParts[i] > currentParts[i]) return true;
      if (remoteParts[i] < currentParts[i]) return false;
    }

    return false;
  }

  List<int> _parseVersion(String version) {
    final cleanVersion = version.split('-')[0];
    return cleanVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  }
}

final updateNotifierProvider =
    StateNotifierProvider<UpdateNotifier, UpdateState>((ref) {
      final updateService = ref.watch(updateServiceProvider);
      return UpdateNotifier(updateService);
    });

final shouldShowUpdateNotificationProvider = Provider<bool>((ref) {
  final updateState = ref.watch(updateNotifierProvider);
  return updateState.hasUpdate && !updateState.isLoading;
});
