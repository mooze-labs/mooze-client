import 'package:flutter/material.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/developer/grid_action_button.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Grid of action buttons for developer tools
class DeveloperActionGrid extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onSync;
  final VoidCallback onFullSync;
  final VoidCallback onRescan;
  final VoidCallback onViewLogs;
  final VoidCallback onExportLogs;
  final VoidCallback onClearLogs;
  final VoidCallback onRefund;

  const DeveloperActionGrid({
    super.key,
    required this.isLoading,
    required this.onSync,
    required this.onFullSync,
    required this.onRescan,
    required this.onViewLogs,
    required this.onExportLogs,
    required this.onClearLogs,
    required this.onRefund,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final dividerColor = colorScheme.onSurface.withValues(alpha: 0.08);
    final warningColor = context.appColors.warning;
    final t = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dividerColor),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.build_outlined, color: colorScheme.primary, size: 20),
              const SizedBox(width: 10),
              Text(
                t.developer_tools_title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Text(
              t.developer_tools_subtitle,
              style: textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: dividerColor, height: 1),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              GridActionButton(
                icon: Icons.sync,
                label: t.developer_action_light_sync,
                tooltip: t.developer_action_light_sync_tooltip,
                onPressed: onSync,
                enabled: !isLoading,
              ),
              GridActionButton(
                icon: Icons.sync_alt,
                label: t.developer_action_full_sync,
                tooltip: t.developer_action_full_sync_tooltip,
                onPressed: onFullSync,
                enabled: !isLoading,
                iconColor: warningColor,
              ),
              GridActionButton(
                icon: Icons.radar,
                label: t.developer_action_rescan,
                tooltip: t.developer_action_rescan_tooltip,
                onPressed: onRescan,
                enabled: !isLoading,
              ),
              GridActionButton(
                icon: Icons.task_alt_rounded,
                label: t.developer_action_refund,
                tooltip: t.developer_action_refund_tooltip,
                onPressed: onRefund,
                enabled: !isLoading,
                iconColor: warningColor,
              ),
              GridActionButton(
                icon: Icons.article_outlined,
                label: t.developer_action_view_logs,
                tooltip: t.developer_action_view_logs_tooltip,
                onPressed: onViewLogs,
                enabled: !isLoading,
              ),
              GridActionButton(
                icon: Icons.download_outlined,
                label: t.developer_action_export,
                tooltip: t.developer_action_export_tooltip,
                onPressed: onExportLogs,
                enabled: !isLoading,
              ),
              GridActionButton(
                icon: Icons.delete_sweep_outlined,
                label: t.developer_action_clear_logs,
                tooltip: t.developer_action_clear_logs_tooltip,
                onPressed: onClearLogs,
                enabled: !isLoading,
                iconColor: colorScheme.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
