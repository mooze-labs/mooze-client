import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/settings/presentation/screens/developer_screen.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';

/// Dialog for choosing how to export logs (email or share)
class ExportLogsDialog extends StatelessWidget {
  const ExportLogsDialog({super.key});

  static Future<ExportMethod?> show(BuildContext context) {
    return showDialog<ExportMethod>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const ExportLogsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withValues(alpha: 0.2),
              ),
              child: Icon(
                Icons.file_download,
                size: 40,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Exportar Logs',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Os logs do aplicativo ajudam nossa equipe a resolver problemas. Como você gostaria de compartilhar?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.outlineVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Enviar por E-mail',
              onPressed: () {
                Navigator.of(context).pop(ExportMethod.email);
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop(ExportMethod.share);
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: BorderSide(color: colorScheme.outline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Salvar/Compartilhar',
                style: TextStyle(
                  color: colorScheme.onSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
