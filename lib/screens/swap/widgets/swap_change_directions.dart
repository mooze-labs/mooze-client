import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/screens/swap/providers/swap_input_provider.dart';
import 'package:mooze_mobile/screens/swap/providers/swap_quote_provider.dart';

class SwapChangeDirections extends ConsumerWidget {
  const SwapChangeDirections({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swapInput = ref.watch(swapInputNotifierProvider);

    return IconButton(
      onPressed: () {
        final sendAsset = swapInput.sendAsset;
        final recvAsset = swapInput.recvAsset;

        ref.read(swapInputNotifierProvider.notifier).changeSendAsset(recvAsset);
        ref.read(swapInputNotifierProvider.notifier).changeRecvAsset(sendAsset);
        ref
            .read(swapInputNotifierProvider.notifier)
            .changeSendAssetSatoshiAmount(0);

        if (sendAsset == AssetCatalog.bitcoin ||
            recvAsset == AssetCatalog.bitcoin) {
          ref.read(swapQuoteNotifierProvider.notifier).stopQuote();
          return;
        }

        ref
            .read(swapQuoteNotifierProvider.notifier)
            .requestNewQuote(
              recvAsset.id,
              swapInput.recvAssetSatoshiAmount,
              sendAsset.id,
            );
      },
      icon: const Icon(Icons.swap_vert),
    );
  }
}
