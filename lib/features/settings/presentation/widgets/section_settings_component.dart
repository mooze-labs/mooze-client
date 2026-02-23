import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/settings/presentation/models/settings_structure.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/divider_component.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/label_settings_component.dart';

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
          Padding(
            padding: const EdgeInsets.only(top: 15, left: 20, bottom: 10),
            child: Text(title, style: const TextStyle(fontSize: 12)),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
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
                      if (index < settingsItems.length - 1)
                        const LabelDivider(),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
