import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/settings/presentation/models/settings_structure.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/divider_component.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/label_settings_component.dart';

class SectionSettingsProfile extends StatelessWidget {
  final String image;
  final String name;
  final String email;
  final List<ConfigStructure>? settingsItems;

  const SectionSettingsProfile({
    super.key,
    required this.image,
    required this.name,
    required this.email,
    this.settingsItems,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20, left: 20, bottom: 10),
                  child: Row(
                    children: [
                      const CircleAvatar(radius: 25),
                      const SizedBox(
                        width: 10,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            email,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF7C7C7C)),
                          )
                        ],
                      )
                    ],
                  ),
                ),
                if (settingsItems != null)
                  Column(
                    children: List.generate(
                      settingsItems!.length,
                      (index) {
                        final item = settingsItems![index];
                        return Column(
                          children: [
                            const LabelDivider(),
                            LabelSettings(
                              title: item.title,
                              iconPathSVG: item.iconSvgPath,
                              action: item.action,
                            ),
                            // if (index < settingsItems!.length - 1)
                            // const LabelDivider(),
                          ],
                        );
                      },
                    ),
                  ),
                if (settingsItems == null || settingsItems == [])
                  const SizedBox(
                    height: 10,
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
