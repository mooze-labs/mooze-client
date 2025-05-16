import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/providers/fiat/fiat_provider.dart';
import 'package:mooze_mobile/screens/receive_pix/providers/asset_amount_provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/pix_input_provider.dart';
import '../providers/fee_rate_provider.dart';

class TransactionInfoDisplay extends ConsumerWidget {
  const TransactionInfoDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetAmount = ref.watch(assetAmountProvider);
    final pixInput = ref.watch(pixInputProvider);

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
                "Dados da transação",
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
                  Image.asset(pixInput.asset.logoPath, width: 24, height: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      pixInput.asset.name,
                      style: TextStyle(
                        fontFamily: "roboto",
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 10),
                  assetAmount.when(
                    data:
                        (data) => Text(
                          "≈ ${data.toStringAsFixed(pixInput.asset.precision)}",
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
                          highlightColor: const Color.fromARGB(
                            255,
                            100,
                            95,
                            95,
                          ),
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
              SizedBox(height: 10),
              if (pixInput.address.isNotEmpty)
                Text(
                  "${pixInput.address.substring(0, 4)} ${pixInput.address.substring(4, 8)} ${pixInput.address.substring(8, 12)} ... ${pixInput.address.substring(pixInput.address.length - 8, pixInput.address.length - 4)} ${pixInput.address.substring(pixInput.address.length - 4)}",
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
      ],
    );
  }
}
