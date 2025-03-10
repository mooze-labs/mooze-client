import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/providers/fiat/fiat_provider.dart';
import 'package:mooze_mobile/providers/multichain/owned_assets_provider.dart';

class BalanceDisplay extends ConsumerWidget {
  final bool isBalanceVisible;

  const BalanceDisplay({Key? key, required this.isBalanceVisible});

  double sumFiatAmount(
    AsyncValue<List<OwnedAsset>> ownedAssets,
    AsyncValue<Map<String, double>> assetPrices,
  ) {
    return assetPrices.when(
      loading: () => 0.0,
      error: (err, stack) {
        print("[ERROR] Could not retrieve asset prices: $err");
        return 0.0;
      },
      data: (prices) {
        return ownedAssets.when(
          loading: () => 0.0,
          error: (err, stack) {
            print("[ERROR] Could not retrieve owned assets: $err");
            return 0.0;
          },
          data: (assets) {
            return assets
                .where(
                  (ownedAsset) =>
                      (ownedAsset.asset.fiatPriceId != null) &&
                      (prices.containsKey(ownedAsset.asset.fiatPriceId)),
                )
                .map(
                  (ownedAsset) =>
                      prices[ownedAsset.asset.fiatPriceId]! *
                      (ownedAsset.amount / pow(10, ownedAsset.asset.precision)),
                )
                .fold<double>(0, (value, element) => value + element);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Computed total in BRL
    final ownedAssets = ref.watch(ownedAssetsNotifierProvider);
    final fiatPrices = ref.watch(fiatPricesProvider);

    // Show/Hide logic
    final displayBrl =
        isBalanceVisible
            ? "R\$ ${sumFiatAmount(ownedAssets, fiatPrices).toStringAsFixed(2)}"
            : "R\$ ••••";

    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            "Saldo total",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: "roboto",
              fontSize: 24.0,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.0,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          SizedBox(height: 10),
          Text(
            displayBrl,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 40.0,
              fontFamily: "roboto",
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class ErrorBalanceDisplay extends StatelessWidget {
  final String error;

  const ErrorBalanceDisplay({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displayBtc = "Error: $error";
    final displayBrl = "Error";

    return SizedBox(
      height: 200,

      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRect(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1E1E1E), // dark
                      Color(0xFFD973C1), // pink
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            left: 16,
            bottom: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Saldo",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  displayBtc,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayBrl,
                  style: const TextStyle(color: Colors.red, fontSize: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
