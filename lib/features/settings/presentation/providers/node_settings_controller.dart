import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/domain/entities/chain.dart';
import 'package:mooze_mobile/domain/entities/wallet_credentials.dart';
import 'package:mooze_mobile/features/settings/presentation/providers/usecase_providers.dart';
import 'package:mooze_mobile/shared/key_management/providers/mnemonic_provider.dart';
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
  /// human-readable error string on failure. After persistence runs a V2
  /// reconnect so chain services pick up the new endpoint policy on the
  /// next refresh tick.
  Future<String?> save() async {
    final current = state.value;
    if (current == null) return 'State not loaded';

    state = const AsyncLoading<NodeSettingsState>().copyWithPrevious(state);

    try {
      if (current.isCustomMode) {
        final btcUrl = current.bitcoinUrl.trim();
        final liquidUrl = current.liquidUrl.trim();

        // A blank endpoint means "use the default node for this chain",
        // persisted by clearing any previously stored custom URL. This
        // lets users customise just one of the two chains.
        final btcResult = btcUrl.isEmpty
            ? await ref.read(clearBitcoinNodeUrlUseCaseProvider).call()
            : await ref.read(setBitcoinNodeUrlUseCaseProvider).call(btcUrl);
        if (btcResult is Failure<void>) return btcResult.message;

        final liquidResult = liquidUrl.isEmpty
            ? await ref.read(clearLiquidNodeUrlUseCaseProvider).call()
            : await ref.read(setLiquidNodeUrlUseCaseProvider).call(liquidUrl);
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

      // V2 reconnect: walks every chain service, idempotently disconnects
      // any that are not operational, reconnects with the current
      // mnemonic, and runs a light refresh. Serialised with the periodic
      // ticker by the orchestrator's `SingleFlight`. Best-effort — if the
      // mnemonic is missing or the orchestrator can't be reached, the
      // next periodic sync still picks up the saved endpoints.
      try {
        final mnemonicOption = await ref.read(mnemonicProvider.future);
        final mnemonic = mnemonicOption.toNullable();
        if (mnemonic != null) {
          final sync = await ref.read(syncOrchestratorProvider.future);
          await sync.reconnect(
            credentials: WalletCredentials(
              mnemonic: mnemonic,
              network: AppNetwork.mainnet,
            ),
          );
        }
      } catch (_) {
        // Endpoint reconnect is best-effort.
      }

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
