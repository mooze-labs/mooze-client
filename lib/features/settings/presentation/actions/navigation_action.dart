import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/action.dart';

class Navigation extends SettingsActions {
  final String rota;
  final BuildContext context;

  Navigation({
    required this.rota,
    required this.context,
  });

  @override
  void execute() {
    context.go(rota);
  }
}
