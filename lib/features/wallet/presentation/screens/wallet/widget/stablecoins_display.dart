import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';

import '../providers/stablecoins_provider.dart';

class StablecoinItem extends StatelessWidget {
  const StablecoinItem({
    super.key,
    required this.title,
    required this.icon,
    required this.subtitle,
    required this.value,
  });

  final String title;
  final Widget icon;
  final String subtitle;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondary,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        leading: icon,
      ),
    );
  }
}

class StablecoinsDisplay extends ConsumerWidget {
  const StablecoinsDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stablecoins = ref.watch(stablecoinsProvider);

    return stablecoins.when(
      data:
          (data) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Stablecoins",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ...data.keys
                    .map(
                      (key) => StablecoinItem(
                        title: key.name,
                        icon: Image.asset(
                          'assets/images/icons/${key.ticker.toLowerCase()}.png',
                          width: 24,
                          height: 24,
                        ),
                        subtitle: key.ticker.toUpperCase(),
                        value: ref
                            .watch(balanceProvider(key))
                            .when(
                              data: (data) => data.toString(),
                              error: (error, stack) => 'N/A',
                              loading: () => '...',
                            ),
                      ),
                    )
                    .toList(),
              ],
            ),
          ),
      error: (error, stack) => Text('Error: $error'),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}
