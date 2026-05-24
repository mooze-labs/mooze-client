import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/features/swap/presentation/utils/post_swap_refresh.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/pending_swaps_provider.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart' as core;
import 'package:mooze_mobile/themes/theme_context_x.dart';
import '../providers/btc_lbtc_swap_controller_provider.dart';
import '../widgets/btc_lbtc_confirm_bottom_sheet.dart';
import '../screens/swap_success_screen.dart';

class BtcLbtcSwapHelper {
  final BuildContext context;
  final WidgetRef ref;

  BtcLbtcSwapHelper(this.context, this.ref);

  bool _isPendingPaymentsError(String error) {
    return error.toLowerCase().contains('cannot drain') &&
        error.toLowerCase().contains('pending payments');
  }

  void _showPendingPaymentsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final t = AppLocalizations.of(context);
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color(0xFF1C1C1C),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withValues(alpha: 0.2),
                  ),
                  child: const Icon(
                    Icons.schedule,
                    size: 40,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  t.swap_pending_dialog_title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  t.swap_error_processing,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[400],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      t.common_understood,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> executeSwap({
    required BigInt amount,
    required core.Asset fromAsset,
    required core.Asset toAsset,
    bool drain = false,
  }) async {
    final isPegIn = fromAsset == core.Asset.btc;

    if (!context.mounted) return;

    final controllerEither = await ref.read(
      btcLbtcSwapControllerProvider.future,
    );

    await controllerEither.match(
      (error) async {
        if (context.mounted) {
          if (_isPendingPaymentsError(error)) {
            _showPendingPaymentsDialog();
          } else {
            _showErrorSnackBar(error);
          }
        }
      },
      (controller) async {
        if (!context.mounted) return;

        BtcLbtcConfirmBottomSheet.show(
          context,
          amount: amount,
          isPegIn: isPegIn,
          controller: controller,
          drain: drain,
          onConfirm: (feeRateSatPerVByte) async {
            // Surface the swap in the home transaction list the instant
            // the user confirms. The optimistic row carries the
            // "where did my money go" answer while Breez SDK works
            // through the chain swap; `pendingSwapsReconciliationProvider`
            // drops it as soon as the persisted store catches up.
            final pendingSwaps =
                ref.read(pendingSwapsProvider.notifier);
            final localId = pendingSwaps.start(
              fromAsset: fromAsset,
              toAsset: toAsset,
              sentAmount: amount,
              // No fee-aware estimate available here; show the gross
              // amount and let the real row replace it with the
              // post-fee figure once Breez emits.
              estimatedReceivedAmount: amount,
            );

            try {
              pendingSwaps.markBroadcasting(localId);
              if (isPegIn) {
                final result =
                    await controller
                        .executePegIn(
                          amount: amount,
                          feeRateSatPerVByte: feeRateSatPerVByte,
                          drain: drain,
                        )
                        .run();

                if (context.mounted) {
                  Navigator.of(context).pop();

                  result.match(
                    (error) {
                      pendingSwaps.markFailed(localId, error: error);
                      if (_isPendingPaymentsError(error)) {
                        _showPendingPaymentsDialog();
                      } else {
                        _showErrorSnackBar(error);
                      }
                    },
                    (transaction) {
                      pendingSwaps.markBroadcasted(
                        localId,
                        // `transaction.id` here is the BDK (peg-in) /
                        // LWK (peg-out) lockup tx id, NOT the Breez
                        // short swap id. Store it as `breezTxId` only
                        // and leave `breezSwapId` null — the polling
                        // watcher resolves the real swap id (e.g.
                        // `wCaunaTNZaHv`) shortly afterwards via
                        // `findBreezChainSwapId`.
                        breezTxId: transaction.sendTxId ?? transaction.id,
                      );
                      _refreshAfterSwap();
                      _showSuccessScreen(
                        amount,
                        fromAsset, // BTC
                        toAsset, // LBTC
                        transaction.id,
                      );
                    },
                  );
                }
              } else {
                final result =
                    await controller
                        .executePegOut(
                          amount: amount,
                          feeRateSatPerVByte: feeRateSatPerVByte,
                          drain: drain,
                        )
                        .run();

                if (context.mounted) {
                  Navigator.of(context).pop();

                  result.match(
                    (error) {
                      pendingSwaps.markFailed(localId, error: error);
                      if (_isPendingPaymentsError(error)) {
                        _showPendingPaymentsDialog();
                      } else {
                        _showErrorSnackBar(error);
                      }
                    },
                    (transaction) {
                      pendingSwaps.markBroadcasted(
                        localId,
                        // `transaction.id` here is the BDK (peg-in) /
                        // LWK (peg-out) lockup tx id, NOT the Breez
                        // short swap id. Store it as `breezTxId` only
                        // and leave `breezSwapId` null — the polling
                        // watcher resolves the real swap id (e.g.
                        // `wCaunaTNZaHv`) shortly afterwards via
                        // `findBreezChainSwapId`.
                        breezTxId: transaction.sendTxId ?? transaction.id,
                      );
                      // Refresh UI immediately after peg-out is confirmed.
                      // See _refreshAfterSwap docstring above.
                      _refreshAfterSwap();
                      _showSuccessScreen(
                        amount,
                        fromAsset,
                        toAsset,
                        transaction.id,
                      );
                    },
                  );
                }
              }
            } catch (e) {
              pendingSwaps.markFailed(localId, error: e.toString());
              if (context.mounted) {
                Navigator.of(context).pop();
                _showErrorSnackBar(
                  AppLocalizations.of(
                    context,
                  ).swap_error_unexpected(e.toString()),
                );
              }
            }
          },
        );
      },
    );
  }

  void _showSuccessScreen(
    BigInt amount,
    core.Asset fromAsset,
    core.Asset toAsset,
    String txId,
  ) {
    final amountInBtc = amount.toDouble() / 100000000;

    SwapSuccessScreen.show(
      context,
      fromAsset: fromAsset,
      toAsset: toAsset,
      amountSent: amountInBtc,
      amountReceived: amountInBtc,
      txid: txId,
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red[700]),
    );
  }

  /// Fire-and-forget staggered wallet refresh — see
  /// [triggerPostSwapRefresh] for the schedule. Replaces the older
  /// single-shot light refresh: the first tick still fires
  /// immediately so balances catch up the moment the SDK returns,
  /// and a couple of follow-up ticks catch BDK/LWK reconciliations
  /// and on-chain confirmations that land a few seconds later.
  void _refreshAfterSwap() {
    triggerPostSwapRefresh(ref);
  }
}
