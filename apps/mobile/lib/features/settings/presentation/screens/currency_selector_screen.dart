import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/label_settings.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/settings_page_scaffold.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import '../widgets/currency/currency_list.dart';

class CurrencySelectorScreen extends StatelessWidget {
  const CurrencySelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return SettingsPageScaffold(
      title: t.currency_select_title,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CurrencyList(title: t.currency_display_label),
            // The note lines up with the section title.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SettingsPageScaffold.gutter + LabelSettings.horizontalPadding,
                10,
                SettingsPageScaffold.gutter + LabelSettings.horizontalPadding,
                0,
              ),
              child: Text(
                t.currency_display_description,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
