import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/deposit_amount_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/selected_asset_provider.dart';
import 'package:mooze_mobile/features/pix/shared/di/providers/pix_tutorial_service_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

enum PixTutorialStage {
  inactive,

  home,

  receive,

  confirm,
}

const double kPixTutorialDemoAmount = 20.0;

class PixTutorialState {
  final PixTutorialStage stage;
  final int runId;

  const PixTutorialState({
    this.stage = PixTutorialStage.inactive,
    this.runId = 0,
  });

  bool get isActive => stage != PixTutorialStage.inactive;

  PixTutorialState copyWith({PixTutorialStage? stage, int? runId}) =>
      PixTutorialState(stage: stage ?? this.stage, runId: runId ?? this.runId);
}

class PixTutorialController extends Notifier<PixTutorialState> {
  final GlobalKey homePixButtonKey = GlobalKey();
  final GlobalKey bottomNavPixKey = GlobalKey();
  final GlobalKey assetSelectorKey = GlobalKey();
  final GlobalKey limitsKey = GlobalKey();
  final GlobalKey amountInputKey = GlobalKey();
  final GlobalKey slideButtonKey = GlobalKey();

  @override
  PixTutorialState build() => const PixTutorialState();

  bool get hasSeen => ref.read(pixTutorialServiceProvider).isTutorialShown();

  void start() {
    _resetDemoState();
    state = PixTutorialState(
      stage: PixTutorialStage.home,
      runId: state.runId + 1,
    );
  }

  /// Advances to the receive-screen group (steps 3–7).
  void toReceive() {
    state = state.copyWith(stage: PixTutorialStage.receive);
  }

  /// Advances to the confirmation-screen group (steps 8–9).
  void toConfirm() {
    state = state.copyWith(stage: PixTutorialStage.confirm);
  }

  /// Pre-fills the demonstration amount (step 6 → 7 transition).
  void applyDemoAmount() {
    ref.read(depositAmountProvider.notifier).state = kPixTutorialDemoAmount;
  }

  /// Step 4: previews the L-BTC option in the asset selector to show the user
  /// they can change the receiving asset.
  void previewLbtcAsset() {
    ref.read(selectedAssetProvider.notifier).state = Asset.lbtc;
  }

  /// Step 4 → 5: restores the default dePIX asset after the preview.
  void restoreDefaultAsset() {
    ref.read(selectedAssetProvider.notifier).state = Asset.depix;
  }

  /// Replays the tutorial from the beginning without persisting completion.
  void restart() {
    _resetDemoState();
    state = PixTutorialState(
      stage: PixTutorialStage.home,
      runId: state.runId + 1,
    );
  }

  /// Completes the tutorial: persists the flag and clears demo state so it
  /// never auto-starts again. Keeps [PixTutorialState.runId] monotonic so a
  /// later replay never collides with the run that just finished.
  Future<void> finish() async {
    _resetDemoState();
    state = state.copyWith(stage: PixTutorialStage.inactive);
    await ref.read(pixTutorialServiceProvider).setTutorialShown();
  }

  /// User dismissed the tutorial early — treated like completion so it does
  /// not nag on the next launch (matches Merchant Mode behaviour).
  Future<void> skip() async {
    await finish();
  }

  void _resetDemoState() {
    ref.read(depositAmountProvider.notifier).state = 0.0;
    ref.read(selectedAssetProvider.notifier).state = Asset.depix;
  }
}

final pixTutorialControllerProvider =
    NotifierProvider<PixTutorialController, PixTutorialState>(
      PixTutorialController.new,
    );
