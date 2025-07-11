import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';

class BitcoinDisplay extends ConsumerWidget {
  const BitcoinDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bitcoin = ref.watch(balanceProvider(Asset.btc));

    return bitcoin.when(
      data:
          (data) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Bitcoin", style: Theme.of(context).textTheme.titleMedium),
                Card(
                  color: Theme.of(context).colorScheme.secondary,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      "Liquid Bitcoin",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      "L-BTC",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: Text(
                      "${(data / BigInt.from(100000000)).toStringAsFixed(8)} BTC",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    leading: Icon(
                      Icons.currency_bitcoin,
                      size: 24,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
      error: (error, stackTrace) => Text(error.toString()),
      loading: () => const CircularProgressIndicator(),
    );
  }
}
