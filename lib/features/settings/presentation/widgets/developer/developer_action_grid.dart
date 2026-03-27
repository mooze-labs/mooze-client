import 'package:flutter/material.dart';
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
                'Ferramentas',
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
              'Sincronização, logs e diagnósticos',
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
                label: 'Light Sync',
                tooltip: 'Fast sync (transactions, balances, prices)',
                onPressed: onSync,
                enabled: !isLoading,
              ),
              GridActionButton(
                icon: Icons.sync_alt,
                label: 'Full Sync',
                tooltip: 'Complete blockchain sync',
                onPressed: onFullSync,
                enabled: !isLoading,
                iconColor: warningColor,
              ),
              GridActionButton(
                icon: Icons.radar,
                label: 'Rescan',
                tooltip: 'Rescan onchain swaps',
                onPressed: onRescan,
                enabled: !isLoading,
              ),
              GridActionButton(
                icon: Icons.task_alt_rounded,
                label: 'Reembolso',
                tooltip: 'Navigate to refund screen',
                onPressed: onRefund,
                enabled: !isLoading,
                iconColor: warningColor,
              ),
              GridActionButton(
                icon: Icons.article_outlined,
                label: 'View Logs',
                tooltip: 'View application logs',
                onPressed: onViewLogs,
                enabled: !isLoading,
              ),
              GridActionButton(
                icon: Icons.download_outlined,
                label: 'Export',
                tooltip: 'Export logs as ZIP',
                onPressed: onExportLogs,
                enabled: !isLoading,
              ),
              GridActionButton(
                icon: Icons.delete_sweep_outlined,
                label: 'Clear Logs',
                tooltip: 'Clear all logs',
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
