import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/widgets/developer/grid_action_button.dart';
import 'package:mooze_mobile/themes/app_extra_colors.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final extraColors = Theme.of(context).extension<AppExtraColors>();
    final warningColor = extraColors?.warning ?? Colors.orange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.build, color: colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Tools',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
              tooltip: 'Complete blockchain sync',
              onPressed: onRefund,
              enabled: !isLoading,
              iconColor: warningColor,
            ),
            GridActionButton(
              icon: Icons.article,
              label: 'View Logs',
              tooltip: 'View application logs',
              onPressed: onViewLogs,
              enabled: !isLoading,
            ),
            GridActionButton(
              icon: Icons.download,
              label: 'Export',
              tooltip: 'Export logs as ZIP',
              onPressed: onExportLogs,
              enabled: !isLoading,
            ),
            GridActionButton(
              icon: Icons.delete_sweep,
              label: 'Clear Logs',
              tooltip: 'Clear all logs',
              onPressed: onClearLogs,
              enabled: !isLoading,
              iconColor: colorScheme.error,
            ),
          ],
        ),
      ],
    );
  }
}
