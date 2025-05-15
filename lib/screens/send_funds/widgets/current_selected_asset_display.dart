import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/providers/fiat/fiat_provider.dart';
import 'package:mooze_mobile/providers/multichain/owned_assets_provider.dart';
import 'package:mooze_mobile/screens/send_funds/providers/send_user_input_provider.dart';
import 'package:shimmer/shimmer.dart';

class CurrentSelectedAssetDisplay extends ConsumerWidget {
  const CurrentSelectedAssetDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sendUserInput = ref.watch(sendUserInputProvider);
    final ownedAssets = ref.watch(ownedAssetsNotifierProvider);
    final fiatPrices = ref.watch(fiatPricesProvider);
    final baseCurrency = ref.watch(baseCurrencyProvider);

    if (ownedAssets == null ||
        ownedAssets.value == null ||
        sendUserInput.asset == null) {
      return const SizedBox.shrink();
    }

    final ownedAsset = ownedAssets.value!.firstWhere(
      (oa) => oa.asset.id == sendUserInput.asset!.id,
      orElse: () => OwnedAsset.zero(sendUserInput.asset!),
    );

    if (ownedAsset == null) {
      return const SizedBox.shrink();
    }

    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Saldo disponível",
            style: TextStyle(
              fontSize: 20,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 5),
          Text(
            "${(ownedAsset.amount / pow(10, ownedAsset.asset.precision)).toStringAsFixed(ownedAsset.asset.precision)} ${ownedAsset.asset.ticker}",
            style: TextStyle(
              fontSize: 30,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          fiatPrices.when(
            data:
                (data) => Text(
                  "${(ownedAsset!.amount / pow(10, ownedAsset!.asset.precision) * data[ownedAsset!.asset.fiatPriceId]!).toStringAsFixed(2)} $baseCurrency",
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
            error:
                (_, __) => Text(
                  "Erro ao carregar preço",
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
            loading:
                () => Shimmer.fromColors(
                  baseColor: Theme.of(context).colorScheme.onSurface,
                  highlightColor: Theme.of(context).colorScheme.onSurface,
                  child: Container(
                    width: 100,
                    height: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
