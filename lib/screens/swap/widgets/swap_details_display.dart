import 'dart:math';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/models/sideswap.dart';
import 'package:mooze_mobile/providers/sideswap_repository_provider.dart';
import 'package:mooze_mobile/screens/swap/providers/swap_input_provider.dart';
import 'package:mooze_mobile/screens/swap/providers/swap_quote_provider.dart';

class SendAssetDetailsDisplay extends StatelessWidget {
  final String assetTicker;
  final String assetName;
  final int assetAmount;
  final String assetImage;
  const SendAssetDetailsDisplay({
    super.key,
    required this.assetTicker,
    required this.assetName,
    required this.assetAmount,
    required this.assetImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Você envia $assetTicker",
              style: const TextStyle(fontSize: 16),
            ),
            Image.asset(assetImage, width: 16, height: 16),
          ],
        ),
        Text(
          "${(assetAmount / pow(10, 8)).toStringAsFixed((assetAmount > 1000000000) ? 2 : 8)}",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(assetName, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class ReceiveAssetDetailsDisplay extends ConsumerStatefulWidget {
  final String assetTicker;
  final String assetName;
  final String assetImage;
  const ReceiveAssetDetailsDisplay({
    super.key,
    required this.assetTicker,
    required this.assetName,
    required this.assetImage,
  });

  @override
  ConsumerState<ReceiveAssetDetailsDisplay> createState() =>
      _ReceiveAssetDetailsDisplayState();
}

class _ReceiveAssetDetailsDisplayState
    extends ConsumerState<ReceiveAssetDetailsDisplay> {
  StreamSubscription<QuoteResponse>? _quoteSubscription;
  int _displayAmount = 0;

  @override
  void initState() {
    super.initState();
    final sideswapClient = ref.read(sideswapRepositoryProvider);
    sideswapClient.ensureConnection();

    // Subscribe to the quote response stream
    _quoteSubscription = sideswapClient.quoteResponseStream.listen((
      quoteResponse,
    ) {
      final swapInput = ref.read(swapInputNotifierProvider);
      if (quoteResponse.isSuccess && quoteResponse.quote != null) {
        final isSendAssetQuoteAmount =
            swapInput.sendAssetSatoshiAmount ==
            quoteResponse.quote!.quoteAmount;
        // Convert satoshis to BTC/LBTC
        final amount =
            isSendAssetQuoteAmount
                ? quoteResponse.quote!.baseAmount
                : quoteResponse.quote!.quoteAmount;

        setState(() {
          _displayAmount = amount;
        });
      }
    });
  }

  @override
  void dispose() {
    _quoteSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Você recebe ${widget.assetTicker}",
              style: const TextStyle(fontSize: 16),
            ),
            Image.asset(widget.assetImage, width: 16, height: 16),
          ],
        ),
        Text(
          "~${(_displayAmount / pow(10, 8)).toStringAsFixed((_displayAmount > 1000000000) ? 2 : 8)}",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(widget.assetName, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class SwapDetailsDisplay extends ConsumerWidget {
  const SwapDetailsDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swapInput = ref.watch(swapInputNotifierProvider);
    final swapQuote = ref.watch(swapQuoteNotifierProvider);

    if (kDebugMode) {
      print("Swap quote: $swapQuote");
      print("Quote amount: ${swapQuote?.quote?.quoteAmount}");
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SendAssetDetailsDisplay(
          assetTicker: swapInput.sendAsset.ticker,
          assetName: swapInput.sendAsset.name,
          assetAmount: swapInput.sendAssetSatoshiAmount,
          assetImage: swapInput.sendAsset.logoPath,
        ),
        const SizedBox(width: 16),
        const Icon(Icons.arrow_forward_ios),
        const SizedBox(width: 16),
        ReceiveAssetDetailsDisplay(
          assetTicker: swapInput.recvAsset.ticker,
          assetName: swapInput.recvAsset.name,
          assetImage: swapInput.recvAsset.logoPath,
        ),
      ],
    );
  }
}

class SwapFeesDisplay extends ConsumerStatefulWidget {
  const SwapFeesDisplay({super.key});

  @override
  ConsumerState<SwapFeesDisplay> createState() => _SwapFeesDisplayState();
}

class _SwapFeesDisplayState extends ConsumerState<SwapFeesDisplay> {
  StreamSubscription<QuoteResponse>? _quoteSubscription;
  int _serverFee = 0;
  int _fixedFee = 0;
  double _exchangeRate = 0;

  @override
  void initState() {
    super.initState();
    final sideswapClient = ref.read(sideswapRepositoryProvider);
    sideswapClient.ensureConnection();

    // Subscribe to the quote response stream
    _quoteSubscription = sideswapClient.quoteResponseStream.listen((
      quoteResponse,
    ) {
      if (quoteResponse.isSuccess && quoteResponse.quote != null) {
        final swapInput = ref.read(swapInputNotifierProvider);
        final quote = quoteResponse.quote!;

        // Calculate exchange rate (quote amount / base amount)
        final baseAmount = quote.baseAmount / pow(10, 8);
        final quoteAmount = quote.quoteAmount / pow(10, 8);
        final rate = quoteAmount / baseAmount;

        setState(() {
          _serverFee = quote.serverFee;
          _fixedFee = quote.fixedFee;
          _exchangeRate = rate;
        });
      }
    });
  }

  @override
  void dispose() {
    _quoteSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final swapInput = ref.watch(swapInputNotifierProvider);

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Taxas", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Taxa do servidor",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(width: 8),
            Text(
              "${(_serverFee / pow(10, 8)).toStringAsFixed((_serverFee > 1000000000) ? 2 : 8)} L-BTC",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Taxa fixa", style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(width: 8),
            Text(
              "${(_fixedFee / pow(10, 8)).toStringAsFixed((_fixedFee > 1000000000) ? 2 : 8)} L-BTC",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }
}
