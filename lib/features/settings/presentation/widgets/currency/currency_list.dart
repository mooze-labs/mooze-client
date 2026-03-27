import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'currency_selector_item.dart';

class CurrencyList extends ConsumerWidget {
  const CurrencyList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCurrency = ref.watch(currencyControllerProvider);
    final controller = ref.read(currencyControllerProvider.notifier);
    final availableCurrencies = controller.availableCurrencies;

    return ListView.separated(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: availableCurrencies.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = availableCurrencies[index];
        final isSelected = currentCurrency == item.currency;

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => controller.setCurrency(item.currency),
          child: CurrencySelectorItem(item: item, isSelected: isSelected),
        );
      },
    );
  }
}
