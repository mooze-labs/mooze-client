import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/logs/clear_logs_option.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
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
      builder: (context) =>
          ClearLogsDialog(totalLogs: totalLogs, dbLogs: dbLogs),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;
    final t = AppLocalizations.of(context);

    return GlassDialog(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delete_sweep_outlined,
              size: 32,
              color: context.appColors.warning,
            ),
            const SizedBox(height: 16),
            Text(
              t.clear_logs_title,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.clear_logs_description,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            GlassPanel(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClearOption(
                    title: t.clear_logs_option_memory,
                    description: t.clear_logs_option_memory_desc(totalLogs),
                    icon: Icons.memory_outlined,
                    value: 'memory',
                  ),
                  const PanelDivider(indent: 52),
                  ClearOption(
                    title: t.clear_logs_option_db,
                    description: t.clear_logs_option_db_desc(dbLogs),
                    icon: Icons.storage_outlined,
                    value: 'database',
                  ),
                  const PanelDivider(indent: 52),
                  ClearOption(
                    title: t.clear_logs_option_all,
                    description: t.clear_logs_option_all_desc,
                    icon: Icons.delete_forever_outlined,
                    value: 'all',
                    iconColor: colors.errorColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(minimumSize: const Size(88, 48)),
              child: Text(
                t.clear_logs_cancel,
                style: textTheme.labelLarge?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
