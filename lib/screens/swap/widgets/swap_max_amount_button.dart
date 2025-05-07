import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/providers/multichain/owned_assets_provider.dart';
import 'package:mooze_mobile/screens/swap/providers/swap_input_provider.dart';
import 'package:mooze_mobile/screens/swap/providers/swap_quote_provider.dart';

class MaxAmountButton extends ConsumerWidget {
  final TextEditingController amountController;

  const MaxAmountButton({super.key, required this.amountController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: () {
        final swapInput = ref.read(swapInputNotifierProvider);
        final ownedAssets = ref.read(ownedAssetsNotifierProvider);

        ownedAssets.when(
          loading: () => null,
          error: (err, stack) => null,
          data: (assets) {
            final selectedAsset = assets.firstWhere(
              (asset) => asset.asset.id == swapInput.sendAsset.id,
              orElse: () => OwnedAsset.zero(swapInput.sendAsset),
            );

            final maxAmount = selectedAsset.amount;

            // Update the amount in the provider
            ref
                .read(swapInputNotifierProvider.notifier)
                .changeSendAssetSatoshiAmount(maxAmount);

            // Update the text field with the formatted amount
            final formattedAmount = (maxAmount / pow(10, 8)).toStringAsFixed(8);
            amountController.text = formattedAmount;

            // Trigger quote update if amount is not zero
            if (maxAmount > 0) {
              ref
                  .read(swapQuoteNotifierProvider.notifier)
                  .requestNewQuote(
                    swapInput.sendAsset.id,
                    maxAmount,
                    swapInput.recvAsset.id,
                  );
            } else {
              ref.read(swapQuoteNotifierProvider.notifier).stopQuote();
            }
          },
        );
      },
      child: Text(
        'MAX',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
