import 'package:flutter/widgets.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/action.dart';

class CallbackSettingsAction extends SettingsActions {
  final VoidCallback onExecute;

  CallbackSettingsAction(this.onExecute);

  @override
  void execute() => onExecute();
}
