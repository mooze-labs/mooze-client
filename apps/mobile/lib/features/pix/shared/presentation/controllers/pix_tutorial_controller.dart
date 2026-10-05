import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/deposit_amount_provider.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/providers/selected_asset_provider.dart';
import 'package:mooze_mobile/features/pix/shared/di/providers/pix_tutorial_service_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

enum PixTutorialStage { inactive, receive, confirm }

const double kPixTutorialDemoAmount = 50.0;

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
  final GlobalKey assetSelectorKey = GlobalKey();
  final GlobalKey limitsKey = GlobalKey();
  final GlobalKey amountInputKey = GlobalKey();
  final GlobalKey slideButtonKey = GlobalKey();

  @override
  PixTutorialState build() => const PixTutorialState();

  Future<bool> hasSeen() => ref.read(pixTutorialServiceProvider).isTutorialShown();

  /// Starts the tutorial on the receive screen. The tutorial no longer
  /// auto-runs on the home screen; it begins the first time the user opens
  /// PIX, when the steps are relevant.
  void start() {
    _resetDemoState();
    state = PixTutorialState(
      stage: PixTutorialStage.receive,
      runId: state.runId + 1,
    );
  }

  /// Starts the tutorial only on the user's first visit to PIX. The flag
  /// read is async, so the tutorial starts one tick after the call.
  Future<void> startIfUnseen() async {
    if (state.isActive) return;
    final seen = await hasSeen().catchError((Object _) => true);
    if (seen || state.isActive) return;
    start();
  }

  /// Kept for callers that advance from an earlier stage; now a no-op alias
  /// for the starting stage.
  void toReceive() {
    state = state.copyWith(stage: PixTutorialStage.receive);
  }

  /// Advances to the confirmation-screen step (slide to generate).
  void toConfirm() {
    state = state.copyWith(stage: PixTutorialStage.confirm);
  }

  /// Pre-fills the demonstration amount before highlighting the field.
  void applyDemoAmount() {
    ref.read(depositAmountProvider.notifier).state = kPixTutorialDemoAmount;
  }

  /// Replays the tutorial from the beginning without persisting completion.
  void restart() => start();

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
