import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/models/sideswap.dart';
import 'package:mooze_mobile/providers/sideswap_repository_provider.dart';
import 'package:mooze_mobile/screens/swap/peg_confirm.dart';
import 'package:mooze_mobile/screens/swap/providers/swap_asset_type_provider.dart';
import 'package:mooze_mobile/screens/swap/providers/swap_base_asset_provider.dart';
import 'package:mooze_mobile/screens/swap/providers/swap_input_provider.dart';
import 'package:mooze_mobile/screens/swap/providers/swap_quote_asset_provider.dart';
import 'package:mooze_mobile/screens/swap/providers/swap_quote_provider.dart';
import 'package:mooze_mobile/screens/swap/widgets/swap_details_display.dart';
import 'package:mooze_mobile/screens/swap/finish_swap.dart';
import 'package:mooze_mobile/widgets/swipe_to_confirm.dart';

class SwapConfirm extends ConsumerStatefulWidget {
  const SwapConfirm({super.key});

  @override
  ConsumerState<SwapConfirm> createState() => _SwapConfirmState();
}

class _SwapConfirmState extends ConsumerState<SwapConfirm> {
  StreamSubscription<QuoteResponse>? _quoteSubscription;
  SideswapQuote? _currentQuote;

  @override
  void initState() {
    super.initState();
    final sideswapClient = ref.read(sideswapRepositoryProvider);
    sideswapClient.ensureConnection();

    _quoteSubscription = sideswapClient.quoteResponseStream.listen((
      quoteResponse,
    ) {
      if (!mounted) return;
      if (quoteResponse.isSuccess && quoteResponse.quote != null) {
        setState(() {
          _currentQuote = quoteResponse.quote;
        });
      }
    });
  }

  @override
  void dispose() {
    _quoteSubscription?.cancel();
    _currentQuote = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final swapInput = ref.watch(swapInputNotifierProvider);
    final assetType = ref.watch(swapAssetTypeNotifierProvider);
    final baseAsset = ref.watch(swapBaseAssetNotifierProvider);
    final quoteAsset = ref.watch(swapQuoteAssetNotifierProvider);

    if (_currentQuote == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final quote = _currentQuote!;
    final isSendAssetBase = swapInput.sendAsset.liquidAssetId == baseAsset;

    final sentAmount = isSendAssetBase ? quote.baseAmount : quote.quoteAmount;
    final receivedAmount =
        isSendAssetBase ? quote.quoteAmount : quote.baseAmount;
    final totalFees = quote.fixedFee + quote.serverFee;

    if (kDebugMode) {
      print("Asset type: $assetType");
      print("Base asset: $baseAsset");
      print("Quote asset: $quoteAsset");
      print("Send asset: ${swapInput.sendAsset.id}");
      print("Recv asset: ${swapInput.recvAsset.id}");
      print("Send asset satoshi amount: ${swapInput.sendAssetSatoshiAmount}");
      print("Recv asset satoshi amount: ${receivedAmount}");
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          // Cancel subscription first
          await _quoteSubscription?.cancel();
          _quoteSubscription = null;
          _currentQuote = null;

          // Then stop quotes and reset state
          ref.read(sideswapRepositoryProvider).stopQuotes();
          ref.read(swapQuoteNotifierProvider.notifier).stopQuote();

          ref
              .read(swapInputNotifierProvider.notifier)
              .changeSendAssetSatoshiAmount(0);
          ref
              .read(swapInputNotifierProvider.notifier)
              .changeRecvAssetSatoshiAmount(0);
          ref
              .read(swapInputNotifierProvider.notifier)
              .changeSendAsset(AssetCatalog.getById("lbtc")!);
          ref
              .read(swapInputNotifierProvider.notifier)
              .changeRecvAsset(AssetCatalog.getById("depix")!);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Confirmar swap')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FittedBox(child: SwapDetailsDisplay()),
                      const SizedBox(height: 16),
                      const FittedBox(child: SwapFeesDisplay()),
                    ],
                  ),
                ),
                const Spacer(),
                SwipeToConfirm(
                  text: "Realizar swap",
                  onConfirm: () {
                    if (swapInput.sendAsset != AssetCatalog.bitcoin &&
                        swapInput.recvAsset != AssetCatalog.bitcoin) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => FinishSwapScreen(
                                quoteId: quote.quoteId,
                                ttl: quote.ttl,
                                sentAsset: swapInput.sendAsset,
                                receivedAsset: swapInput.recvAsset,
                                receivedAmount: receivedAmount,
                                sentAmount: sentAmount,
                                fees: totalFees,
                              ),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
