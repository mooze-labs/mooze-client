import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../providers/swap_controller.dart' as sc;
import 'package:mooze_mobile/shared/entities/asset.dart' as core;
import 'package:mooze_mobile/shared/widgets/info_row.dart';
import 'package:mooze_mobile/shared/widgets/buttons/slide_to_confirm_button.dart';
import '../screens/swap_success_screen.dart';

class ConfirmSwapBottomSheet extends ConsumerStatefulWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onError;

  const ConfirmSwapBottomSheet({super.key, this.onSuccess, this.onError});

  static void show(
    BuildContext context, {
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) =>
              ConfirmSwapBottomSheet(onSuccess: onSuccess, onError: onError),
    );
  }

  @override
  ConsumerState<ConfirmSwapBottomSheet> createState() =>
      _ConfirmSwapBottomSheetState();
}

class _ConfirmSwapBottomSheetState
    extends ConsumerState<ConfirmSwapBottomSheet> {
  bool _isConfirming = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sc.swapControllerProvider);
    final controller = ref.read(sc.swapControllerProvider.notifier);
    final quote = state.currentQuote?.quote;
    final millisecondsRemaining =
        state.millisecondsRemaining ?? state.ttlMilliseconds;

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.55,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1C),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Center(
              child: Text(
                'Confirmar Swap',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (millisecondsRemaining != null)
              Center(
                child: Chip(
                  label: Text(_formatDuration(millisecondsRemaining)),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                children: [
                  const Spacer(),
                  _fromToSummary(context, state),
                  const Spacer(),
                  if (state.error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '${state.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
            if (quote != null) ...[
              const Divider(),
              InfoRow(
                label: 'Taxa do servidor',
                value: _formatFee(state, quote.serverFee),
              ),
              InfoRow(
                label: 'Taxa fixa',
                value: _formatFee(state, quote.fixedFee),
              ),
              InfoRow(
                label: 'Total de taxas',
                value: _formatFee(state, quote.serverFee + quote.fixedFee),
                valueFontWeight: FontWeight.bold,
              ),
            ],

            SizedBox(height: 24),

            SlideToConfirmButton(
              text:
                  _isConfirming || state.loading
                      ? 'Confirmando...'
                      : 'Confirmar Swap',
              isLoading: _isConfirming || state.loading,
              onSlideComplete:
                  _isConfirming || state.loading
                      ? () {}
                      : () => _confirmSwap(context, controller),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatFee(sc.SwapState state, int feeSats) {
    final feeId = state.feeAssetId;
    final asset = feeId != null ? core.Asset.fromId(feeId) : core.Asset.btc;
    if (asset == core.Asset.btc || asset == core.Asset.lbtc) {
      return '$feeSats SATS';
    } else {
      final value = feeSats / 100000000;
      return '${value.toStringAsFixed(4)} ${asset.ticker}';
    }
  }

  Future<void> _confirmSwap(
    BuildContext context,
    sc.SwapController controller,
  ) async {
    setState(() => _isConfirming = true);

    final currentState = ref.read(sc.swapControllerProvider);
    final sendId = currentState.lastSendAssetId;
    final receiveId = currentState.lastReceiveAssetId;
    final sendAmount = currentState.sendAmount;
    final receiveAmount = currentState.receiveAmount;

    try {
      final result = await controller.confirmSwap();
      if (!mounted) return;
      result.match(
        (err) {
          Navigator.of(context).pop();

          widget.onError?.call();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro na confirmação: $err'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        },
        (txid) {
          Navigator.of(context).pop();

          // Chama o callback de sucesso para limpar campos
          widget.onSuccess?.call();

          final sendAsset =
              sendId != null ? core.Asset.fromId(sendId) : core.Asset.btc;
          final receiveAsset =
              receiveId != null
                  ? core.Asset.fromId(receiveId)
                  : core.Asset.usdt;

          if (sendAmount != null && receiveAmount != null) {
            final amountSent = sendAmount.toDouble() / 100000000;
            final amountReceived = receiveAmount.toDouble() / 100000000;

            SwapSuccessScreen.show(
              context,
              fromAsset: sendAsset,
              toAsset: receiveAsset,
              amountSent: amountSent,
              amountReceived: amountReceived,
              txid: txid,
            );
          }
        },
      );
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  String _formatDuration(int millis) {
    if (millis <= 0) return '00:00';
    final totalSeconds = (millis / 1000).ceil();
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _fromToSummary(BuildContext context, sc.SwapState state) {
    final sendId = state.lastSendAssetId;
    final receiveId = state.lastReceiveAssetId;
    final sendAsset =
        sendId != null ? core.Asset.fromId(sendId) : core.Asset.btc;
    final receiveAsset =
        receiveId != null ? core.Asset.fromId(receiveId) : core.Asset.usdt;

    String formatAmount(core.Asset a, int amountSats) {
      final v = amountSats.toDouble() / 100000000;
      return v.toStringAsFixed(8);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [Color(0xFF2D2E2A), Color(0xFFE91E63)],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Você envia'),
                      const SizedBox(width: 10),
                      SvgPicture.asset(
                        sendAsset.iconPath,
                        width: 15,
                        height: 15,
                      ),
                    ],
                  ),
                  Text(
                    state.lastAmount != null
                        ? formatAmount(sendAsset, state.lastAmount!.toInt())
                        : '0',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(sendAsset.name.toLowerCase()),
                ],
              ),
              const Spacer(),
              SvgPicture.asset(
                'assets/icons/menu/arrow.svg',
                width: 25,
                height: 25,
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Você recebe'),
                      const SizedBox(width: 10),
                      SvgPicture.asset(
                        receiveAsset.iconPath,
                        width: 15,
                        height: 15,
                      ),
                    ],
                  ),
                  Text(
                    state.receiveAmount != null
                        ? formatAmount(receiveAsset, state.receiveAmount!)
                        : '0',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(receiveAsset.name.toLowerCase()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
