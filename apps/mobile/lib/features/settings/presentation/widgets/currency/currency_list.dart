import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/label_divider.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/settings_choice_row.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/settings_glass_section.dart';
import 'package:mooze_mobile/shared/prices/providers/currency_controller_provider.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The currencies the app can show amounts in, as a single-choice list in
/// a glass panel. Each currency shows its symbol, its code, and its name.
class CurrencyList extends ConsumerWidget {
  const CurrencyList({super.key, this.title});

  /// Optional title above the panel.
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCurrency = ref.watch(currencyControllerProvider);
    final controller = ref.read(currencyControllerProvider.notifier);
    final availableCurrencies = controller.availableCurrencies(context);

    return SettingsGlassSection(
      title: title,
      child: Column(
        children: [
          for (var i = 0; i < availableCurrencies.length; i++) ...[
            if (i > 0) const LabelDivider(),
            SettingsChoiceRow(
              // The currency symbol takes the icon slot. A long symbol, such
              // as R$, shrinks to fit it.
              leading: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  availableCurrencies[i].icon,
                  textScaler: TextScaler.noScaling,
                  style: context.textTheme.titleMedium?.copyWith(
                    color: context.colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              title: availableCurrencies[i].code,
              subtitle: availableCurrencies[i].name,
              selected: currentCurrency == availableCurrencies[i].currency,
              onTap: () =>
                  controller.setCurrency(availableCurrencies[i].currency),
            ),
          ],
        ],
      ),
    );
  }
}
