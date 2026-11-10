import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/settings/presentation/providers/theme_mode_provider.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/label_divider.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/label_settings.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/settings_choice_row.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/settings_glass_section.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/settings_page_scaffold.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_icon.dart';

class ThemeSelectorScreen extends ConsumerWidget {
  const ThemeSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final currentMode = ref.watch(themeModeProvider);

    final options = [
      _ThemeOption(
        mode: ThemeMode.system,
        label: t.theme_system,
        iconAsset: 'assets/icons/menu/settings/theme.svg',
      ),
      _ThemeOption(
        mode: ThemeMode.light,
        label: t.theme_light,
        iconAsset: 'assets/icons/menu/settings/sun.svg',
      ),
      _ThemeOption(
        mode: ThemeMode.dark,
        label: t.theme_dark,
        iconAsset: 'assets/icons/menu/settings/moon.svg',
      ),
    ];

    return SettingsPageScaffold(
      title: t.settings_theme,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: SettingsGlassSection(
          title: t.settings_section_appearance,
          child: Column(
            children: [
              for (var i = 0; i < options.length; i++) ...[
                if (i > 0) const LabelDivider(),
                SettingsChoiceRow(
                  title: options[i].label,
                  leading: AppIcon(
                    path: options[i].iconAsset,
                    size: LabelSettings.iconSize,
                  ),
                  selected: currentMode == options[i].mode,
                  onTap: () => ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(options[i].mode),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeOption {
  final ThemeMode mode;
  final String label;
  final String iconAsset;

  const _ThemeOption({
    required this.mode,
    required this.label,
    required this.iconAsset,
  });
}
