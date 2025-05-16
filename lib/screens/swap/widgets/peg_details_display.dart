import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/models/network.dart';
import 'package:mooze_mobile/providers/sideswap_repository_provider.dart';
import 'package:mooze_mobile/providers/wallet/bitcoin_fee_provider.dart';
import 'package:mooze_mobile/providers/wallet/liquid_fee_provider.dart';
import 'package:mooze_mobile/screens/swap/providers/swap_input_provider.dart';
import 'package:mooze_mobile/providers/wallet/network_fee_provider.dart';
import 'package:shimmer/shimmer.dart';

class PegSendAssetDetailsDisplay extends ConsumerWidget {
  const PegSendAssetDetailsDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swapInput = ref.watch(swapInputNotifierProvider);
    final sendAsset = swapInput.sendAsset;
    final sendAmount = swapInput.sendAssetSatoshiAmount;
    final networkFees = ref.watch(networkFeeProviderProvider);

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Você envia ${sendAsset.ticker}",
              style: const TextStyle(fontSize: 16),
            ),
            Image.asset(sendAsset.logoPath, width: 16, height: 16),
          ],
        ),
        networkFees.when(
          data: (fees) {
            return Text(
              "${(sendAmount / pow(10, 8)).toStringAsFixed((sendAmount > 1000000000) ? 2 : 8)}",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            );
          },
          loading:
              () => Shimmer.fromColors(
                baseColor: const Color.fromARGB(255, 77, 72, 72)!,
                highlightColor: const Color.fromARGB(255, 100, 95, 95)!,
                child: Container(
                  width: 120,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 116, 115, 115),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
          error: (e, __) {
            if (kDebugMode) {
              print("Error: ${e.toString()}");
            }
            return Text(
              "${(sendAmount / pow(10, 8)).toStringAsFixed((sendAmount > 1000000000) ? 2 : 8)}",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            );
          },
        ),
        Text(sendAsset.name, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class PegRecvAssetDetailsDisplay extends ConsumerWidget {
  const PegRecvAssetDetailsDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swapInput = ref.watch(swapInputNotifierProvider);
    final recvAsset =
        (swapInput.sendAsset == AssetCatalog.bitcoin)
            ? AssetCatalog.getById("lbtc")!
            : AssetCatalog.bitcoin!;
    final recvAmount = swapInput.sendAssetSatoshiAmount * 0.99;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Você recebe ${recvAsset.ticker}",
              style: const TextStyle(fontSize: 16),
            ),
            Image.asset(recvAsset.logoPath, width: 16, height: 16),
          ],
        ),
        Text(
          "~ ${(recvAmount / pow(10, 8)).toStringAsFixed((recvAmount > 1000000000) ? 2 : 8)}",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(recvAsset.name, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class PegDetailsDisplay extends ConsumerWidget {
  const PegDetailsDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        PegSendAssetDetailsDisplay(),
        const SizedBox(width: 16),
        const Icon(Icons.arrow_forward_ios),
        const SizedBox(width: 16),
        PegRecvAssetDetailsDisplay(),
      ],
    );
  }
}

class PegFeesDisplay extends ConsumerWidget {
  const PegFeesDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideswap = ref.watch(sideswapRepositoryProvider);
    final swapInput = ref.watch(swapInputNotifierProvider);
    final networkFees =
        (swapInput.sendAsset.network == Network.bitcoin)
            ? ref.watch(bitcoinFeeProvider(3))
            : ref.watch(liquidFeeProvider);

    return FutureBuilder(
      future: sideswap.getServerStatus(),
      builder: (context, AsyncSnapshot<dynamic> snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final serverStatus = snapshot.data;
        final minAmount =
            swapInput.sendAsset == AssetCatalog.bitcoin
                ? serverStatus?.minPegInAmount
                : serverStatus?.minPegOutAmount;

        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Dados da transação",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  "Valor mínimo:",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 8),
                Text(
                  "${(minAmount! / pow(10, 8)).toStringAsFixed((minAmount > 1000000000) ? 2 : 8)} ${swapInput.sendAsset.ticker}",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  "Taxa de conversão:",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 8),
                Text("0,1%", style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 4),
            networkFees.when(
              data:
                  (fees) => Row(
                    children: [
                      Text(
                        "Taxa de rede:",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${fees?.absoluteFees}",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
              loading:
                  () => Shimmer.fromColors(
                    baseColor: const Color.fromARGB(255, 77, 72, 72)!,
                    highlightColor: const Color.fromARGB(255, 100, 95, 95)!,
                    child: Container(
                      width: 100,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 116, 115, 115),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
              error: (e, __) {
                if (kDebugMode) {
                  print("Error: ${e.toString()}");
                }
                return const SizedBox();
              },
            ),
          ],
        );
      },
    );
  }
}
