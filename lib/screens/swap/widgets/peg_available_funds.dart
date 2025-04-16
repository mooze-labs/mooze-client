import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/providers/multichain/owned_assets_provider.dart';

class PegAvailableFunds extends ConsumerWidget {
  final bool pegIn;

  const PegAvailableFunds({super.key, required this.pegIn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownedAssets = ref.watch(ownedAssetsNotifierProvider);

    return ownedAssets.when(
      loading: () => Text(""),
      error: (err, stackTrace) => Text(""),
      data: (ownedAssets) {
        final ownedAsset =
            (pegIn)
                ? ownedAssets.firstWhere((asset) => asset.asset.id == "btc")
                : ownedAssets.firstWhere((asset) => asset.asset.id == "lbtc");

        return Text(
          "Valor disponível (menos taxas): ${((ownedAsset.amount - 250) / pow(10, ownedAsset.asset.precision)).toStringAsFixed(ownedAsset.asset.precision)} ${ownedAsset.asset.ticker}",
        );
      },
    );
  }
}
