import 'package:flutter/foundation.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/action.dart';

class Toggle extends SettingsActions {
  final bool value;

  /// Called with the new value. Null disables the switch, for example while
  /// a change runs.
  final ValueChanged<bool>? onChange;

  Toggle({required this.value, required this.onChange});

  @override
  void execute() {}
}
