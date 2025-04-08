import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/providers/fiat/fiat_provider.dart';

class AvailableFunds extends ConsumerWidget {
  final OwnedAsset? ownedAsset;

  const AvailableFunds({super.key, required this.ownedAsset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fiatPrices = ref.watch(fiatPricesProvider);
    final baseCurrency = ref.watch(baseCurrencyProvider);

    if (ownedAsset == null) {
      return Text("");
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
            "${(ownedAsset!.amount / pow(10, ownedAsset!.asset.precision)).toStringAsFixed(ownedAsset!.asset.precision)} ${ownedAsset!.asset.ticker}",
            style: TextStyle(
              fontSize: 30,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          fiatPrices.when(
            loading: () => Text(""),
            error: (err, stack) => Text(""),
            data: (data) {
              if (!data.containsKey(ownedAsset!.asset.fiatPriceId))
                return Text("");

              return Text(
                "${(ownedAsset!.amount / pow(10, ownedAsset!.asset.precision) * data[ownedAsset!.asset.fiatPriceId]!).toStringAsFixed(2)} $baseCurrency",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 20,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
