import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/pix_input_provider.dart';
import '../providers/fee_rate_provider.dart';

class FeeRateDisplay extends ConsumerWidget {
  const FeeRateDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pixInput = ref.watch(pixInputProvider);
    final feeRate = ref.watch(feeRateProvider);

    return Container(
      padding: const EdgeInsets.all(16),
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              feeRate.when(
                data:
                    (data) =>
                        (pixInput.amountInCents == 0)
                            ? Text("-")
                            : (pixInput.amountInCents <= 55 * 100)
                            ? Text(
                              "R\$ 1.00 (taxa fixa)",
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            )
                            : Text(
                              "${data.toStringAsFixed(2)}%",
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.primary,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Taxa de parceiros",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
              Text(
                "R\$ 1.00",
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
