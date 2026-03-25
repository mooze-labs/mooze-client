import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';

class CurrencySelectorItem extends StatelessWidget {
  final CurrencyItem item;
  final bool isSelected;

  const CurrencySelectorItem({
    super.key,
    required this.item,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Row(
        children: [
          _buildCurrencyIcon(),
          const SizedBox(width: 12),
          _buildCurrencyInfo(context, colorScheme),
          const SizedBox(width: 12),
          _buildSelectionIndicator(),
        ],
      ),
    );
  }

  Widget _buildCurrencyIcon() {
    return CircleAvatar(child: Text(item.icon));
  }

  Widget _buildCurrencyInfo(BuildContext context, ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.code,
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.name,
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionIndicator() {
    return IgnorePointer(
      child: Checkbox(value: isSelected, onChanged: (value) {}),
    );
  }
}
