import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/providers/multichain/owned_assets_provider.dart';
import 'package:mooze_mobile/providers/wallet/network_fee_provider.dart';
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
        final networkFees = ref.read(networkFeeProviderProvider);

        ownedAssets.when(
          loading: () => null,
          error: (err, stack) => null,
          data: (assets) {
            final selectedAsset = assets.firstWhere(
              (asset) => asset.asset.id == swapInput.sendAsset.id,
              orElse: () => OwnedAsset.zero(swapInput.sendAsset),
            );

            int maxAmount = selectedAsset.amount;

            // Subtract network fee if the asset is BTC or LBTC
            networkFees.whenOrNull(
              data: (fees) {
                if (selectedAsset.asset.id == AssetCatalog.getById("btc")?.id) {
                  // Subtract Bitcoin network fee
                  maxAmount = max(
                    0,
                    maxAmount - fees.bitcoinFast.absoluteFees - 1,
                  );
                } else if (selectedAsset.asset.id ==
                    AssetCatalog.getById("lbtc")?.id) {
                  // Subtract Liquid network fee
                  maxAmount = max(0, maxAmount - fees.liquid.absoluteFees - 1);
                }
              },
            );

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
