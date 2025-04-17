import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/utils/fees.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddressDisplay extends StatelessWidget {
  final String address;
  final int fiatAmount; // Amount in cents
  final Asset asset;
  final bool hasReferral;
  final double fiatPrice;

  const AddressDisplay({
    super.key,
    required this.address,
    required this.asset,
    required this.fiatAmount,
    required this.hasReferral,
    required this.fiatPrice,
  });

  Map<String, double> calculateAmounts(
    int fiatAmountInCents,
    double fiatPrice,
  ) {
    if (fiatPrice == 0) return {'amount': 0.0, 'feeRate': 0.0};
    // Convert cents to whole amount
    double fiatAmount = fiatAmountInCents / 100.0;
    double assetAmount = fiatAmount / fiatPrice;

    final feeCalculator = FeeCalculator(
      assetId: asset.id,
      fiatAmount: fiatAmountInCents,
      hasReferral: hasReferral,
    );
    double feeRate = feeCalculator.getFees();
    double amountAfterFees = assetAmount - (assetAmount * feeRate);

    return {'amount': amountAfterFees, 'feeRate': feeRate};
  }

  @override
  Widget build(BuildContext context) {
    final amounts = calculateAmounts(fiatAmount, fiatPrice);
    final assetAmount = amounts['amount']!;
    final feeRate = amounts['feeRate']!;

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
                    assetAmount.toStringAsFixed(asset.precision),
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
                    "${(feeRate * 100).toStringAsFixed(2)}%",
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
