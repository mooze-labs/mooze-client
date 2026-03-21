import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/action.dart';
import 'package:mooze_mobile/shared/widgets/app_snackbar.dart';
import 'package:url_launcher/url_launcher.dart';

class ExternalNavigation extends SettingsActions {
  final String rota;
  final BuildContext context;

  ExternalNavigation({required this.rota, required this.context});

  @override
  void execute() {
    _openLink();
  }

  Future<void> _openLink() async {
    try {
      final uri = Uri.parse(rota);

      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        final bool launchedAlternative = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );

        if (!launchedAlternative) {
          AppSnackBar.error(context, 'Não foi possível abrir o link');
        }
      }
    } catch (e) {
      AppSnackBar.error(context, 'Erro ao tentar abrir o link');
    }
  }
}
