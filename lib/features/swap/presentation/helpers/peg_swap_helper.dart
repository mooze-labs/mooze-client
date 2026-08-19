import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/features/wallet/presentation/providers/pending_swaps_provider.dart';
import 'package:mooze_mobile/shared/entities/asset.dart' as core;
import 'package:mooze_mobile/shared/widgets/app_snackbar.dart';

import '../../di/providers/peg_providers.dart';
import '../../domain/entities/peg.dart';
import '../../domain/entities/peg_error.dart';
import '../../domain/usecases/peg_tracker.dart';
import '../screens/swap_success_screen.dart';
import '../utils/post_swap_refresh.dart';
import '../widgets/btc_lbtc_confirm_bottom_sheet.dart';


class PegSwapHelper {
  PegSwapHelper(this.context, this.ref);

  final BuildContext context;
  final WidgetRef ref;

  Future<void> executeSwap({
    required BigInt amount,
    required core.Asset fromAsset,
    required core.Asset toAsset,
    bool drain = false,
    String? externalBitcoinAddress,
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) async {
    final direction =
        fromAsset == core.Asset.btc ? PegDirection.pegIn : PegDirection.pegOut;

    final orchestrator = await ref.read(pegOrchestratorProvider.future);
    if (orchestrator == null) {
      if (context.mounted) {
        AppSnackBar.error(context, 'Carteira indisponível. Tente novamente.');
      }
      onError?.call();
      return;
    }
    if (!context.mounted) return;

    BtcLbtcConfirmBottomSheet.show(
      context,
      amount: amount,
      isPegIn: direction.isPegIn,
      orchestrator: orchestrator,
      drain: drain,
      onConfirm: (feeRateSatPerVByte, quote) async {
        final sendAmount = quote.amountSat;
        final estimatedReceive = quote.estimatedReceiveSat;

        // Optimistic row so the home list answers "where did my money go" the
        // instant the user confirms.
        final pendingSwaps = ref.read(pendingSwapsProvider.notifier);
        final localId = pendingSwaps.start(
          fromAsset: fromAsset,
          toAsset: toAsset,
          sentAmount: sendAmount,
          estimatedReceivedAmount: estimatedReceive,
        );
        pendingSwaps.markBroadcasting(localId);

        final result =
            await orchestrator
                .execute(
                  direction: direction,
                  amountSat: sendAmount,
                  feeRateSatPerVByte: feeRateSatPerVByte,
                  drain: drain,
                  externalPayoutAddress: externalBitcoinAddress,
                )
                .run();

        if (!context.mounted) return;
        Navigator.of(context).pop();

        result.match(
          (error) {
            pendingSwaps.markFailed(localId, error: error.message);
            _showError(error);
            onError?.call();
          },
          (execution) async {
            pendingSwaps.markBroadcasted(
              localId,
              breezTxId: execution.fundingTxId,
            );

            final tracker = await ref.read(pegTrackerProvider.future);
            tracker.track(
              TrackedPeg(
                orderId: execution.order.orderId,
                direction: direction,
                phase: PegPhase.awaitingDeposit,
                amountSat: sendAmount,
                depositAddress: execution.order.depositAddress,
                fundingTxId: execution.fundingTxId,
              ),
            );

            triggerPostSwapRefresh(ref);
            if (context.mounted) {
              SwapSuccessScreen.show(
                context,
                fromAsset: fromAsset,
                toAsset: toAsset,
                amountSent: sendAmount.toDouble() / 100000000,
                amountReceived: estimatedReceive.toDouble() / 100000000,
                txid: execution.fundingTxId,
              );
            }
            onSuccess?.call();
          },
        );
      },
    );
  }

  void _showError(PegError error) {
    if (!context.mounted) return;
    if (error is PegUnknownOutcome) {
      AppSnackBar.warning(context, error.message);
      return;
    }
    AppSnackBar.error(context, error.message);
  }
}
