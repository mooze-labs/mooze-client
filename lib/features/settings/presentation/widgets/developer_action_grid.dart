import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/widgets/developer/grid_action_button.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.build, color: AppColors.primaryColor, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Tools',
              style: TextStyle(
                color: Colors.white,
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
              iconColor: Colors.orange[400],
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
              iconColor: Colors.orange[700],
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
              iconColor: Colors.red[400],
            ),
          ],
        ),
      ],
    );
  }
}
