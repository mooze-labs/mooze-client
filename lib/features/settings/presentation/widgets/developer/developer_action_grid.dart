import 'package:flutter/material.dart';

import 'package:mooze_mobile/features/settings/presentation/widgets/developer/sync_progress_card.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/developer/grid_action_button.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';


class DeveloperActionGrid extends StatelessWidget {
  const DeveloperActionGrid({
    super.key,
    required this.activeOperation,
    required this.onSync,
    required this.onFullSync,
    required this.onRescan,
    required this.onViewLogs,
    required this.onExportLogs,
    required this.onClearLogs,
    required this.onRefund,
  });

  final DeveloperOperation? activeOperation;
  final VoidCallback onSync;
  final VoidCallback onFullSync;
  final VoidCallback onRescan;
  final VoidCallback onViewLogs;
  final VoidCallback onExportLogs;
  final VoidCallback onClearLogs;
  final VoidCallback onRefund;

  bool get _busy => activeOperation != null;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final extra = context.appColors;
    final warningColor = extra.warning;
    final t = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 10),
              Text(
                t.developer_tools_title,
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              t.developer_tools_subtitle,
              style: tt.bodySmall?.copyWith(color: extra.textSecondary),
            ),
          ),
          const SizedBox(height: 18),
          _SectionLabel(text: 'Synchronisation'),
          const SizedBox(height: 10),
          _ActionRow(
            children: [
              GridActionButton(
                icon: Icons.sync_rounded,
                label: t.developer_action_light_sync,
                subtitle: 'Balances · transactions',
                tooltip: t.developer_action_light_sync_tooltip,
                onPressed: onSync,
                enabled: !_busy,
                loading: activeOperation == DeveloperOperation.lightSync,
              ),
              GridActionButton(
                icon: Icons.sync_alt_rounded,
                label: t.developer_action_full_sync,
                subtitle: 'Light + rescan',
                tooltip: t.developer_action_full_sync_tooltip,
                onPressed: onFullSync,
                enabled: !_busy,
                loading: activeOperation == DeveloperOperation.fullSync,
                iconColor: warningColor,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ActionRow(
            children: [
              GridActionButton(
                icon: Icons.radar_rounded,
                label: t.developer_action_rescan,
                subtitle: 'Onchain swaps',
                tooltip: t.developer_action_rescan_tooltip,
                onPressed: onRescan,
                enabled: !_busy,
                loading: activeOperation == DeveloperOperation.rescan,
              ),
              GridActionButton(
                icon: Icons.task_alt_rounded,
                label: t.developer_action_refund,
                subtitle: 'Pending refunds',
                tooltip: t.developer_action_refund_tooltip,
                onPressed: onRefund,
                enabled: !_busy,
                iconColor: warningColor,
              ),
            ],
          ),
          const SizedBox(height: 22),
          _SectionLabel(text: 'Diagnostics'),
          const SizedBox(height: 10),
          _ActionRow(
            children: [
              GridActionButton(
                icon: Icons.article_outlined,
                label: t.developer_action_view_logs,
                subtitle: 'Live viewer',
                tooltip: t.developer_action_view_logs_tooltip,
                onPressed: onViewLogs,
                enabled: !_busy,
              ),
              GridActionButton(
                icon: Icons.ios_share_rounded,
                label: t.developer_action_export,
                subtitle: 'Share / email ZIP',
                tooltip: t.developer_action_export_tooltip,
                onPressed: onExportLogs,
                enabled: !_busy,
                loading: activeOperation == DeveloperOperation.exportLogs,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ActionRow(
            children: [
              GridActionButton(
                icon: Icons.delete_sweep_outlined,
                label: t.developer_action_clear_logs,
                subtitle: 'Memory · DB · files',
                tooltip: t.developer_action_clear_logs_tooltip,
                onPressed: onClearLogs,
                enabled: !_busy,
                loading: activeOperation == DeveloperOperation.clearLogs,
                iconColor: cs.error,
              ),
              const SizedBox.shrink(),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final extra = context.appColors;
    final tt = context.textTheme;
    return Text(
      text.toUpperCase(),
      style: tt.bodySmall?.copyWith(
        color: extra.textTertiary,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
        fontSize: 10,
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            Expanded(child: children[i]),
            if (i != children.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}
