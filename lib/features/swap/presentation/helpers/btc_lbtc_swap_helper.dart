import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/shared/entities/asset.dart' as core;
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';
import '../providers/btc_lbtc_swap_controller_provider.dart';
import '../widgets/btc_lbtc_confirm_bottom_sheet.dart';
import '../screens/swap_success_screen.dart';

class BtcLbtcSwapHelper {
  final BuildContext context;
  final WidgetRef ref;

  BtcLbtcSwapHelper(this.context, this.ref);

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
          _showErrorSnackBar(error);
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
              final result =
                  isPegIn
                      ? await controller
                          .executePegIn(
                            amount: amount,
                            feeRateSatPerVByte: feeRateSatPerVByte,
                            drain: drain,
                          )
                          .run()
                      : await controller
                          .executePegOut(
                            amount: amount,
                            feeRateSatPerVByte: feeRateSatPerVByte,
                            drain: drain,
                          )
                          .run();

              if (context.mounted) {
                Navigator.of(context).pop();

                result.match((error) => _showErrorSnackBar(error), (
                  transaction,
                ) {
                  ref.invalidate(balanceProvider);
                  _showSuccessScreen(
                    amount,
                    fromAsset,
                    toAsset,
                    transaction.id,
                  );
                });
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
