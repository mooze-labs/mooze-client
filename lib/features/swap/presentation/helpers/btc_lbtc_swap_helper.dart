import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mooze_mobile/shared/entities/asset.dart' as core;
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';
import '../providers/btc_lbtc_swap_controller_provider.dart';
import '../widgets/btc_lbtc_confirm_dialog.dart';
import '../screens/swap_success_screen.dart';

class BtcLbtcSwapHelper {
  final BuildContext context;
  final WidgetRef ref;

  BtcLbtcSwapHelper(this.context, this.ref);

  Future<void> executeSwap({
    required BigInt amount,
    required core.Asset fromAsset,
    required core.Asset toAsset,
  }) async {
    final isPegIn = fromAsset == core.Asset.btc;

    final confirmed = await _showConfirmDialog(amount, isPegIn);
    if (!confirmed) return;

    if (!context.mounted) return;

    _showLoadingDialog();

    try {
      final controllerEither = await ref.read(
        btcLbtcSwapControllerProvider.future,
      );

      await controllerEither.match(
        (error) async {
          if (context.mounted) {
            Navigator.of(context).pop();
            _showErrorSnackBar(error);
          }
        },
        (controller) async {
          final result =
              isPegIn
                  ? await controller.executePegIn(amount).run()
                  : await controller.executePegOut(amount).run();

          if (context.mounted) {
            Navigator.of(context).pop();

            result.match(
              (error) => _showErrorSnackBar(error),
              (transaction) {
                ref.invalidate(balanceProvider);
                _showSuccessScreen(amount, fromAsset, toAsset, transaction.id);
              },
            );
          }
        },
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        _showErrorSnackBar('Erro inesperado: $e');
      }
    }
  }

  Future<bool> _showConfirmDialog(BigInt amount, bool isPegIn) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => BtcLbtcConfirmDialog(
            amount: amount,
            isPegIn: isPegIn,
            onConfirm: () => Navigator.of(context).pop(true),
            onCancel: () => Navigator.of(context).pop(false),
          ),
    );
    return result ?? false;
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
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
