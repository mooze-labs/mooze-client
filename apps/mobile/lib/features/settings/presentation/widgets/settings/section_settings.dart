import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/settings/presentation/models/settings_structure.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/label_divider.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/label_settings.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The title lines up with the row content inside the panel.
          Padding(
            padding: const EdgeInsets.only(top: 20, left: 16, bottom: 8),
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: context.textTheme.labelMedium?.copyWith(
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // A Liquid Glass panel groups the rows. It has no backdrop blur,
          // because it scrolls over a fixed background.
          GlassPanel(
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
          ),
        ],
      ),
    );
  }
}
