import 'dart:math';
import 'dart:ui';
import "package:flutter/material.dart";
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/providers/fiat/fiat_provider.dart';

class CoinBalance extends ConsumerWidget {
  final Asset asset;
  double? fiatPrice;
  final bool isBalanceVisible; // toggle to show/hide amount

  CoinBalance({super.key, required this.asset, this.isBalanceVisible = true});

  void getAssetFiatPrice(AsyncValue<Map<String, double>> fiatPrices) {
    if (asset.fiatPriceId == null) {
      return;
    }

    return fiatPrices.when(
      loading: () => {},
      error: (err, stack) {
        print("[ERROR] Could not load asset prices.");
        return;
      },
      data: (prices) {
        if (!prices.containsKey(asset.fiatPriceId!)) {
          return;
        }

        fiatPrice = prices[asset.fiatPriceId];
        return;
      },
    );
  }

  String _formatBalance() {
    if (!isBalanceVisible) return "••••";
    if (asset.precision == 0) return "$asset.amount".trim();

    final double value = asset.amount / (pow(10, asset.precision));
    return "${value.toStringAsFixed(asset.precision)}".trim();
  }

  String _formatFiatValue() {
    if (fiatPrice == null) return "";
    if (!isBalanceVisible) return "••••";

    final double value = (asset.amount / pow(10, asset.precision)) * fiatPrice!;
    return "R\$ ${value.toStringAsFixed(2)}"; // Format as BRL with 2 decimals
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fiatPrices = ref.watch(fiatPricesProvider);
    getAssetFiatPrice(fiatPrices);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 40, height: 40, child: Image.asset(asset.logoPath)),
          const SizedBox.square(dimension: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.name,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontFamily: "roboto",
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatBalance(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontFamily: "roboto",
                      ),
                    ),
                    Text(
                      _formatFiatValue(),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontFamily: "roboto",
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
