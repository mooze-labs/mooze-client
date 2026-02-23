import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/prices/providers/currency_controller_provider.dart';
import 'currency_selector_item.dart';

class CurrencyList extends ConsumerWidget {
  const CurrencyList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCurrency = ref.watch(currencyControllerProvider);
    final controller = ref.read(currencyControllerProvider.notifier);
    final availableCurrencies = controller.availableCurrencies;

    return ListView.builder(
      physics: const ClampingScrollPhysics(),
      itemCount: availableCurrencies.length,
      itemBuilder: (context, index) {
        final item = availableCurrencies[index];
        final isSelected = currentCurrency == item.currency;

        return _buildCurrencyListItem(
          item: item,
          isSelected: isSelected,
          onTap: () => controller.setCurrency(item.currency),
        );
      },
    );
  }

  Widget _buildCurrencyListItem({
    required CurrencyItem item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: CurrencySelectorItem(item: item, isSelected: isSelected),
        ),
      ),
    );
  }
}
