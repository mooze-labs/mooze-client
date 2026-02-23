import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/widgets/developer/status_item.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.swapCardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            [
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'System Information',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                ..._buildInfoItems(),
              ].expand((widget) sync* {
                yield widget;
                if (widget != const SizedBox(height: 20)) {
                  yield Divider(height: 1, color: Colors.grey[800]);
                }
              }).toList()
              ..removeLast(),
      ),
    );
  }

  List<Widget> _buildInfoItems() {
    return [
      StatusItem(
        label: 'App Version',
        value: '$appVersion ($buildNumber)',
        copiable: true,
      ),
      StatusItem(label: 'SDK Version', value: sdkVersion, copiable: true),
      StatusItem(label: 'Balance', value: '$walletBalance sats'),
      StatusItem(label: 'Pending Balance', value: '$pendingBalance sats'),
      StatusItem(
        label: 'Logs (Memória)',
        value: '$totalLogs',
        onTap: onViewLogs,
      ),
      StatusItem(label: 'Logs (Banco)', value: '$dbLogs', copiable: true),
      StatusItem(
        label: 'Retenção de Logs',
        value: logRetention,
        copiable: true,
      ),
    ];
  }
}
