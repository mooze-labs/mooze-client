import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/providers/multichain/owned_assets_provider.dart';
import 'package:mooze_mobile/screens/swap/providers/swap_input_provider.dart';

class SwapAssetBalance extends StatelessWidget {
  final int balance;
  final String ticker;

  const SwapAssetBalance({
    super.key,
    required this.balance,
    required this.ticker,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      "Saldo: ${(balance / pow(10, 8)).toStringAsFixed(8)} $ticker",
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

class SendAssetBalance extends ConsumerWidget {
  const SendAssetBalance({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swapInput = ref.watch(swapInputNotifierProvider);
    final ownedAssets = ref.watch(ownedAssetsNotifierProvider);
    final sendAsset = swapInput.sendAsset;
    final sendAssetBalance =
        ownedAssets.value
            ?.firstWhere((asset) => asset.asset.id == sendAsset.id)
            .amount;

    return SwapAssetBalance(
      balance: sendAssetBalance ?? 0,
      ticker: sendAsset.ticker,
    );
  }
}

class ReceiveAssetBalance extends ConsumerWidget {
  const ReceiveAssetBalance({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swapInput = ref.watch(swapInputNotifierProvider);
    final ownedAssets = ref.watch(ownedAssetsNotifierProvider);
    final recvAsset = swapInput.recvAsset;
    final recvAssetBalance =
        ownedAssets.value
            ?.firstWhere((asset) => asset.asset.id == recvAsset.id)
            .amount;

    return SwapAssetBalance(
      balance: recvAssetBalance ?? 0,
      ticker: recvAsset.ticker,
    );
  }
}
