import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/settings/presentation/providers/locale_provider.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/label_settings.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/settings_choice_row.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/settings_glass_section.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/settings_page_scaffold.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';

class LanguageSelectorScreen extends ConsumerWidget {
  const LanguageSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final current = ref.watch(localeProvider);

    final options = <_LanguageOption>[
      _LanguageOption(locale: null, label: t.language_system),
      _LanguageOption(locale: const Locale('pt'), label: t.language_portuguese),
      _LanguageOption(locale: const Locale('en'), label: t.language_english),
      _LanguageOption(locale: const Locale('es'), label: t.language_spanish),
    ];

    return SettingsPageScaffold(
      title: t.settings_language,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: SettingsGlassSection(
          title: t.settings_section_language,
          child: Column(
            children: [
              for (var i = 0; i < options.length; i++) ...[
                if (i > 0)
                  const PanelDivider(indent: LabelSettings.horizontalPadding),
                SettingsChoiceRow(
                  title: options[i].label,
                  selected:
                      current?.languageCode == options[i].locale?.languageCode,
                  onTap: () => ref
                      .read(localeProvider.notifier)
                      .setLocale(options[i].locale),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption {
  final Locale? locale;
  final String label;

  const _LanguageOption({required this.locale, required this.label});
}
