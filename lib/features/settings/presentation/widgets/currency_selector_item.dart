import 'package:flutter/material.dart';
import '../../../../shared/prices/providers/currency_controller_provider.dart';

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
          _buildCurrencyInfo(colorScheme),
          const SizedBox(width: 12),
          _buildSelectionIndicator(),
        ],
      ),
    );
  }

  Widget _buildCurrencyIcon() {
    return CircleAvatar(child: Text(item.icon));
  }

  Widget _buildCurrencyInfo(ColorScheme colorScheme) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.code,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.name,
            style: TextStyle(color: colorScheme.outlineVariant, fontSize: 14),
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
