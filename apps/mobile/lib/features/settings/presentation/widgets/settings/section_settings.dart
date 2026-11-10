import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/settings/presentation/models/settings_structure.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/label_divider.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/label_settings.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/settings_glass_section.dart';

class SectionSettings extends StatelessWidget {
  final String title;
  final List<ConfigStructure> settingsItems;

  const SectionSettings({
    super.key,
    required this.title,
    required this.settingsItems,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsGlassSection(
      title: title,
      child: Column(
        children: List.generate(settingsItems.length, (index) {
          final item = settingsItems[index];
          return Column(
            children: [
              LabelSettings(
                title: item.title,
                iconPathSVG: item.iconSvgPath,
                action: item.action,
                highlight: item.highlight,
              ),
              if (index < settingsItems.length - 1) const LabelDivider(),
            ],
          );
        }),
      ),
    );
  }
}
