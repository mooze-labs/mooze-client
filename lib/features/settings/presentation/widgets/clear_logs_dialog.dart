import 'package:flutter/material.dart';
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
      builder: (context) => ClearLogsDialog(
        totalLogs: totalLogs,
        dbLogs: dbLogs,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final extraColors = Theme.of(context).extension<AppExtraColors>();
    final warningColor = extraColors?.warning ?? Colors.orange;

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
                color: warningColor.withValues(alpha: 0.2),
              ),
              child: Icon(
                Icons.delete_sweep,
                size: 40,
                color: warningColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Limpar Logs',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Escolha o que deseja limpar:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.outlineVariant,
              ),
            ),
            const SizedBox(height: 24),
            _ClearOption(
              title: 'Memória',
              description: 'Limpar apenas logs em memória ($totalLogs logs)',
              icon: Icons.memory,
              value: 'memory',
            ),
            const SizedBox(height: 12),
            _ClearOption(
              title: 'Banco de Dados',
              description: 'Limpar apenas logs do banco ($dbLogs logs)',
              icon: Icons.storage,
              value: 'database',
            ),
            const SizedBox(height: 12),
            _ClearOption(
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
                style: TextStyle(color: colorScheme.outlineVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClearOption extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String value;

  const _ClearOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => Navigator.pop(context, value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceBright,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: colorScheme.outlineVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colorScheme.outlineVariant),
          ],
        ),
      ),
    );
  }
}
