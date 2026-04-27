import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/settings/presentation/providers/usecase_providers.dart';
import 'package:mooze_mobile/shared/infra/bdk/providers/blockchain_provider.dart';
import 'package:mooze_mobile/shared/infra/lwk/providers/datasource_provider.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

/// Snapshot of the node configuration screen.
class NodeSettingsState {
  final bool isCustomMode;
  final String bitcoinUrl;
  final String liquidUrl;
  final bool fallbackEnabled;

  const NodeSettingsState({
    required this.isCustomMode,
    required this.bitcoinUrl,
    required this.liquidUrl,
    required this.fallbackEnabled,
  });

  NodeSettingsState copyWith({
    bool? isCustomMode,
    String? bitcoinUrl,
    String? liquidUrl,
    bool? fallbackEnabled,
  }) {
    return NodeSettingsState(
      isCustomMode: isCustomMode ?? this.isCustomMode,
      bitcoinUrl: bitcoinUrl ?? this.bitcoinUrl,
      liquidUrl: liquidUrl ?? this.liquidUrl,
      fallbackEnabled: fallbackEnabled ?? this.fallbackEnabled,
    );
  }
}

class NodeSettingsController extends AsyncNotifier<NodeSettingsState> {
  @override
  Future<NodeSettingsState> build() async {
    final btcResult = await ref.read(getBitcoinNodeUrlUseCaseProvider).call();
    final liquidResult = await ref.read(getLiquidNodeUrlUseCaseProvider).call();
    final fallbackResult =
        await ref.read(getCustomFallbackEnabledUseCaseProvider).call();

    final btcUrl = btcResult.fold((u) => u, (_) => '');
    final liquidUrl = liquidResult.fold((u) => u, (_) => '');
    final fallbackEnabled = fallbackResult.fold((v) => v, (_) => true);

    return NodeSettingsState(
      isCustomMode: btcUrl.isNotEmpty || liquidUrl.isNotEmpty,
      bitcoinUrl: btcUrl,
      liquidUrl: liquidUrl,
      fallbackEnabled: fallbackEnabled,
    );
  }

  /// In-memory toggle — does not persist until [save] is called.
  void setCustomMode(bool isCustom) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(isCustomMode: isCustom));
  }

  void setBitcoinUrl(String value) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(bitcoinUrl: value));
  }

  void setLiquidUrl(String value) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(liquidUrl: value));
  }

  void setFallbackEnabled(bool enabled) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(fallbackEnabled: enabled));
  }

  /// Persists the current form state. Returns null on success or a
  /// human-readable error string on failure. Invalidates the BDK and
  /// LWK datasource providers so the next sync picks up the new
  /// endpoints.
  Future<String?> save() async {
    final current = state.value;
    if (current == null) return 'State not loaded';

    state = const AsyncLoading<NodeSettingsState>().copyWithPrevious(state);

    try {
      if (current.isCustomMode) {
        final setBtc = ref.read(setBitcoinNodeUrlUseCaseProvider);
        final setLiquid = ref.read(setLiquidNodeUrlUseCaseProvider);
        final btcResult = await setBtc.call(current.bitcoinUrl.trim());
        if (btcResult is Failure<void>) return btcResult.message;
        final liquidResult = await setLiquid.call(current.liquidUrl.trim());
        if (liquidResult is Failure<void>) return liquidResult.message;
      } else {
        final clearBtc = ref.read(clearBitcoinNodeUrlUseCaseProvider);
        final clearLiquid = ref.read(clearLiquidNodeUrlUseCaseProvider);
        final btcResult = await clearBtc.call();
        if (btcResult is Failure<void>) return btcResult.message;
        final liquidResult = await clearLiquid.call();
        if (liquidResult is Failure<void>) return liquidResult.message;
      }

      final fallbackResult = await ref
          .read(setCustomFallbackEnabledUseCaseProvider)
          .call(current.fallbackEnabled);
      if (fallbackResult is Failure<void>) return fallbackResult.message;

      // Force a rebuild of the network-facing providers so the next
      // sync pass picks up the new endpoints / fallback policy.
      ref.invalidate(blockchainProvider);
      ref.invalidate(liquidDataSourceProvider);

      state = AsyncData(current);
      return null;
    } catch (e) {
      state = AsyncData(current);
      return e.toString();
    }
  }
}

final nodeSettingsControllerProvider =
    AsyncNotifierProvider<NodeSettingsController, NodeSettingsState>(
  NodeSettingsController.new,
);
