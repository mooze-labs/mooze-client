import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/action.dart';

class ConfigStructure {
  final String? iconSvgPath;
  final String title;
  final SettingsActions? action;
  final Color? color;
  final bool? value;
  final ValueChanged<bool>? onChanged;
  final bool highlight;

  ConfigStructure({
    this.iconSvgPath,
    required this.title,
    this.action,
    this.color,
    this.value,
    this.onChanged,
    this.highlight = false,
  });
}
