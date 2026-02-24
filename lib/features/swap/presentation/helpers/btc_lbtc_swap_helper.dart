import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/shared/entities/asset.dart' as core;
import 'package:mooze_mobile/shared/infra/sync/wallet_data_manager.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
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
                  'Transação Pendente',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Aguarde alguns instantes antes de realizar outro swap. '
                  'Sua transação anterior ainda está sendo processada.',
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
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Entendido',
                      style: TextStyle(
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
            try {
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
                      if (_isPendingPaymentsError(error)) {
                        _showPendingPaymentsDialog();
                      } else {
                        _showErrorSnackBar(error);
                      }
                    },
                    (transaction) {
                      // Refresh UI immediately after peg-in is confirmed
                      ref
                          .read(walletDataManagerProvider.notifier)
                          .refreshAfterTransaction();
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
                      if (_isPendingPaymentsError(error)) {
                        _showPendingPaymentsDialog();
                      } else {
                        _showErrorSnackBar(error);
                      }
                    },
                    (transaction) {
                      // Refresh UI immediately after peg-out is confirmed
                      ref
                          .read(walletDataManagerProvider.notifier)
                          .refreshAfterTransaction();
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
              if (context.mounted) {
                Navigator.of(context).pop();
                _showErrorSnackBar('Erro inesperado: $e');
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
}
