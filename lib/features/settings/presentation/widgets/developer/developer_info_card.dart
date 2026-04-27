import 'package:flutter/material.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/developer/status_item.dart';

/// Information card displaying system and wallet data
class DeveloperInfoCard extends StatelessWidget {
  final String appVersion;
  final String buildNumber;
  final String sdkVersion;
  final String walletBalance;
  final String pendingBalance;
  final int totalLogs;
  final int dbLogs;
  final String logRetention;
  final VoidCallback onViewLogs;

  const DeveloperInfoCard({
    super.key,
    required this.appVersion,
    required this.buildNumber,
    required this.sdkVersion,
    required this.walletBalance,
    required this.pendingBalance,
    required this.totalLogs,
    required this.dbLogs,
    required this.logRetention,
    required this.onViewLogs,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dividerColor = colorScheme.onSurface.withValues(alpha: 0.08);
    final t = AppLocalizations.of(context)!;

    final items = _buildInfoItems(t);

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
              Icon(Icons.info_outline, color: colorScheme.primary, size: 20),
              const SizedBox(width: 10),
              Text(
                t.developer_system_info,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: dividerColor, height: 1),
          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1) Divider(color: dividerColor, height: 1),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildInfoItems(AppLocalizations t) {
    return [
      StatusItem(
        label: t.developer_app_version,
        value: '$appVersion ($buildNumber)',
        copiable: true,
      ),
      StatusItem(
        label: t.developer_sdk_version,
        value: sdkVersion,
        copiable: true,
      ),
      StatusItem(label: t.developer_balance, value: '$walletBalance sats'),
      StatusItem(
        label: t.developer_pending_balance,
        value: '$pendingBalance sats',
      ),
      StatusItem(
        label: t.developer_logs_memory,
        value: '$totalLogs',
        onTap: onViewLogs,
      ),
      StatusItem(label: t.developer_logs_db, value: '$dbLogs', copiable: true),
      StatusItem(
        label: t.developer_log_retention_label,
        value: logRetention,
        copiable: true,
      ),
    ];
  }
}
