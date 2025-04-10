import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/providers/fiat/fiat_provider.dart';
import 'package:mooze_mobile/utils/fees.dart';

class AddressDisplay extends ConsumerWidget {
  final String address;
  final int fiatAmount; // Amount in cents
  final Asset asset;

  const AddressDisplay({
    super.key,
    required this.address,
    required this.asset,
    required this.fiatAmount,
  });

  String getAssetAmount(int fiatAmountInCents, double fiatPrice) {
    if (fiatPrice == 0) return "";
    if (fiatAmountInCents == 0) return "0.00000000";
    // Convert cents to whole amount
    double fiatAmount = (fiatAmountInCents - 100) / 100.0;
    double assetAmount = fiatAmount / fiatPrice;
    double feeRate =
        FeeCalculator(
          assetId: asset.id,
          fiatAmount: fiatAmountInCents,
        ).getFees();
    double amountAfterFees = assetAmount - (assetAmount * feeRate);

    return amountAfterFees.toStringAsFixed(asset.precision);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double fiatPrice = ref
        .watch(fiatPricesProvider)
        .when(
          loading: () => 0.0,
          error: (err, stack) {
            print("[ERROR] Erro ao calcular quantidade: $err");
            return 0.0;
          },
          data: (fiatPrices) {
            if (asset.fiatPriceId == null) return 0.0;
            if (!fiatPrices.containsKey(asset.fiatPriceId)) return 0.0;

            return fiatPrices[asset.fiatPriceId!]!;
          },
        );

    final String assetAmount = getAssetAmount(fiatAmount, fiatPrice);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Dados da transação:",
                style: TextStyle(
                  fontFamily: "roboto",
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
              SizedBox(height: 5),
              Row(
                children: [
                  Image.asset(asset.logoPath, width: 24, height: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      asset.name,
                      style: TextStyle(
                        fontFamily: "roboto",
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.onSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    assetAmount,
                    style: TextStyle(
                      fontFamily: "roboto",
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                "${address.substring(0, 4)} ${address.substring(4, 8)} ${address.substring(8, 12)} ... ${address.substring(address.length - 8, address.length - 4)} ${address.substring(address.length - 4)}",
                style: TextStyle(
                  fontFamily: "roboto",
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Taxa Mooze",
                    style: TextStyle(
                      fontFamily: "roboto",
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                  Text(
                    "${(FeeCalculator(assetId: asset.id, fiatAmount: fiatAmount).getFees() * 100).toStringAsFixed(2)}%",
                    style: TextStyle(
                      fontFamily: "roboto",
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Taxa de parceiros",
                    style: TextStyle(
                      fontFamily: "roboto",
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                  Text(
                    "R\$ 1.00",
                    style: TextStyle(
                      fontFamily: "roboto",
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
