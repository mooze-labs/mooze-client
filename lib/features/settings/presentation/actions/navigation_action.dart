import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/action.dart';

class Navigation extends SettingsActions {
  final String rota;
  final BuildContext context;
  final VerifyPinArgs? verifyPinArgs;

  Navigation({
    required this.rota,
    required this.context,
    this.verifyPinArgs,
  });

  @override
  void execute() {
    context.push(
      rota,
      extra: verifyPinArgs,
    );
  }
}


class VerifyPinArgs {
  final Function()? onPinConfirmed;
  final bool? forceAuth;
  final bool? isAppResuming;

  VerifyPinArgs({
    this.onPinConfirmed,
    this.forceAuth,
    this.isAppResuming,
  });
}
