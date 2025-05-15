import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/providers/fiat/fiat_provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/pix_input_provider.dart';
import '../providers/fee_rate_provider.dart';
import '../providers/asset_amount_provider.dart';

class PixTransactionInfoDisplay extends ConsumerWidget {
  const PixTransactionInfoDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pixInput = ref.watch(pixInputProvider);
    final assetAmount = ref.watch(assetAmountProvider);
    final feeRate = ref.watch(feeRateProvider);
    final fiatPrices = ref.watch(fiatPricesProvider);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Valor",
                  style: TextStyle(
                    fontFamily: "roboto",
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${((pixInput.amountInCents).toDouble() / 100).toStringAsFixed(2)}",
                  style: TextStyle(
                    fontFamily: "roboto",
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSecondary,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Cotação",
                  style: TextStyle(
                    fontFamily: "roboto",
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                fiatPrices.when(
                  data:
                      (data) => Text(
                        "${data[pixInput.asset!.fiatPriceId]!.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontFamily: "roboto",
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                      ),
                  error: (error, stack) => Text("Indisponível"),
                  loading:
                      () => Shimmer.fromColors(
                        baseColor: const Color.fromARGB(255, 77, 72, 72),
                        highlightColor: const Color.fromARGB(255, 100, 95, 95),
                        child: Container(
                          width: 100,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 116, 115, 115),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Quantidade",
                  style: TextStyle(
                    fontFamily: "roboto",
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                assetAmount.when(
                  data:
                      (data) => Text(
                        "${data.toStringAsFixed(pixInput.asset!.precision)} ${pixInput.asset!.ticker}",
                        style: TextStyle(
                          fontFamily: "roboto",
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                      ),
                  error: (error, stack) => Text("Indisponível"),
                  loading:
                      () => Shimmer.fromColors(
                        baseColor: const Color.fromARGB(255, 77, 72, 72),
                        highlightColor: const Color.fromARGB(255, 100, 95, 95),
                        child: Container(
                          width: 100,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 116, 115, 115),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Taxa",
                  style: TextStyle(
                    fontFamily: "roboto",
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                feeRate.when(
                  data:
                      (data) => Text(
                        "${data.toStringAsFixed(2)}%",
                        style: TextStyle(
                          fontFamily: "roboto",
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                      ),
                  error: (error, stack) => Text("Indisponível"),
                  loading:
                      () => Shimmer.fromColors(
                        baseColor: const Color.fromARGB(255, 77, 72, 72),
                        highlightColor: const Color.fromARGB(255, 100, 95, 95),
                        child: Container(
                          width: 100,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 116, 115, 115),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Endereço",
                  style: TextStyle(
                    fontFamily: "roboto",
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${pixInput.address.substring(0, 5)}...${pixInput.address.substring(pixInput.address.length - 5)}",
                  style: TextStyle(
                    fontFamily: "roboto",
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
