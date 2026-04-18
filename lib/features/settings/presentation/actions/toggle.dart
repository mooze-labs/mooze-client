import 'package:flutter/foundation.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/action.dart';

class Toggle extends SettingsActions {
  final bool value;
  final ValueChanged<bool> onChange;

  Toggle({required this.value, required this.onChange});

  @override
  void execute() {}
}
