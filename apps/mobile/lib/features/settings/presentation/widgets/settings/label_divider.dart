import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/label_settings.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';

/// Hairline between two settings rows. It starts at the row text.
class LabelDivider extends StatelessWidget {
  const LabelDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const PanelDivider(indent: LabelSettings.textInset);
  }
}
