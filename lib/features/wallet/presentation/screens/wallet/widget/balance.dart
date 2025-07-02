import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/wallet/providers/price_provider.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/asset_provider.dart';
import '../providers/balance_provider.dart';

class BalanceDisplay extends ConsumerWidget {
  const BalanceDisplay({super.key});

  /// Formats a number with thousands separators
  String _formatWithThousandsSeparator(BigInt value) {
    final String valueStr = value.toString();
    final StringBuffer result = StringBuffer();

    for (int i = 0; i < valueStr.length; i++) {
      if (i > 0 && (valueStr.length - i) % 3 == 0) {
        result.write(' ');
      }
      result.write(valueStr[i]);
    }

    return result.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = ref.watch(assetProvider);
    final balance = ref.watch(balanceProvider(asset));
    //final price = ref.watch(priceProvider);
    final price = 550000;

    return balance.when(
      data:
          (data) => Column(
            children: [
              Text(
                "${_formatWithThousandsSeparator(data)} sats",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                "R\$ ${data / BigInt.from(price)}",
                style: TextStyle(
                  fontSize: 24,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
            ],
          ),
      error:
          (error, stack) =>
              Text("Valor indisponível. Tente novamente mais tarde."),
      loading:
          () => Shimmer.fromColors(
            baseColor: Color.fromARGB(255, 77, 72, 72),
            highlightColor: Color.fromARGB(255, 100, 95, 95),
            child: Container(
              width: 120,
              height: 32,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 116, 115, 115),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
    );
  }
}
