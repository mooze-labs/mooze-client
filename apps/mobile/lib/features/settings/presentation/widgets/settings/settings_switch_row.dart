import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/toggle.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/label_settings.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// A settings row with a title, a muted subtitle, and a switch.
class SettingsSwitchRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final Toggle toggle;

  const SettingsSwitchRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.toggle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: LabelSettings.horizontalPadding,
          vertical: 4,
        ),
        title: Text(
          title,
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.colors.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            subtitle,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
              height: 1.35,
            ),
          ),
        ),
        value: toggle.value,
        onChanged: toggle.onChange,
      ),
    );
  }
}
