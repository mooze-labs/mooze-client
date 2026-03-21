import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/logs/clear_logs_option.dart';
import 'package:mooze_mobile/themes/app_extra_colors.dart';

/// Dialog for choosing what logs to clear (memory, database, or all)
class ClearLogsDialog extends StatelessWidget {
  final int totalLogs;
  final int dbLogs;

  const ClearLogsDialog({
    super.key,
    required this.totalLogs,
    required this.dbLogs,
  });

  static Future<String?> show(
    BuildContext context, {
    required int totalLogs,
    required int dbLogs,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => ClearLogsDialog(totalLogs: totalLogs, dbLogs: dbLogs),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final extraColors = Theme.of(context).extension<AppExtraColors>();
    final warningColor = extraColors?.warning ?? Colors.orange;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                color: warningColor.withValues(alpha: 0.2),
              ),
              child: Icon(Icons.delete_sweep, size: 40, color: warningColor),
            ),
            const SizedBox(height: 20),
            Text(
              'Limpar Logs',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Escolha o que deseja limpar:',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colorScheme.outlineVariant,
              ),
            ),
            const SizedBox(height: 24),
            ClearOption(
              title: 'Memória',
              description: 'Limpar apenas logs em memória ($totalLogs logs)',
              icon: Icons.memory,
              value: 'memory',
            ),
            const SizedBox(height: 12),
            ClearOption(
              title: 'Banco de Dados',
              description: 'Limpar apenas logs do banco ($dbLogs logs)',
              icon: Icons.storage,
              value: 'database',
            ),
            const SizedBox(height: 12),
            ClearOption(
              title: 'Todos',
              description: 'Limpar memória, arquivos e banco',
              icon: Icons.delete_forever,
              value: 'all',
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.outlineVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
