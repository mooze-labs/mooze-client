import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/action.dart';
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
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Não foi possível abrir o link")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao tentar abrir o link")));
    }
  }
}
