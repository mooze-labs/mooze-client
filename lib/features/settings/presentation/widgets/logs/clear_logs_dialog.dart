import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/logs/clear_logs_option.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

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
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final warningColor = context.appColors.warning;
    final t = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: context.colors.backgroundCard,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: warningColor.withValues(alpha: 0.12),
              ),
              child: Icon(
                Icons.delete_sweep_outlined,
                size: 36,
                color: warningColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t.clear_logs_title,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.clear_logs_description,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ClearOption(
              title: t.clear_logs_option_memory,
              description: t.clear_logs_option_memory_desc(totalLogs),
              icon: Icons.memory_outlined,
              value: 'memory',
            ),
            const SizedBox(height: 12),
            ClearOption(
              title: t.clear_logs_option_db,
              description: t.clear_logs_option_db_desc(dbLogs),
              icon: Icons.storage_outlined,
              value: 'database',
            ),
            const SizedBox(height: 12),
            ClearOption(
              title: t.clear_logs_option_all,
              description: t.clear_logs_option_all_desc,
              icon: Icons.delete_forever_outlined,
              value: 'all',
              iconColor: colorScheme.error,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                t.clear_logs_cancel,
                style: textTheme.labelLarge?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
