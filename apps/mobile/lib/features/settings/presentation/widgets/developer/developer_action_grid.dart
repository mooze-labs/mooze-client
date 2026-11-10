import 'package:flutter/material.dart';

import 'package:mooze_mobile/features/settings/presentation/widgets/developer/sync_progress_card.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/settings_glass_section.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Developer actions, as two glass groups of rows split by hairlines:
/// synchronisation and diagnostics.
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
  });

  final DeveloperOperation? activeOperation;
  final VoidCallback onSync;
  final VoidCallback onFullSync;
  final VoidCallback onRescan;
  final VoidCallback onViewLogs;
  final VoidCallback onExportLogs;
  final VoidCallback onClearLogs;

  bool get _busy => activeOperation != null;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colors = context.colors;
    final tt = context.textTheme;
    const divider = PanelDivider(indent: _ActionRow.textInset);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(36, 28, 36, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  t.developer_tools_title,
                  style: tt.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                t.developer_tools_subtitle,
                style: tt.bodySmall?.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
        SettingsGlassSection(
          title: t.developer_section_synchronisation,
          child: Column(
            children: [
              _ActionRow(
                icon: Icons.sync_rounded,
                label: t.developer_action_light_sync,
                subtitle: 'Balances · transactions',
                tooltip: t.developer_action_light_sync_tooltip,
                onPressed: onSync,
                enabled: !_busy,
                loading: activeOperation == DeveloperOperation.lightSync,
              ),
              divider,
              _ActionRow(
                icon: Icons.sync_alt_rounded,
                label: t.developer_action_full_sync,
                subtitle: 'Light + rescan',
                tooltip: t.developer_action_full_sync_tooltip,
                onPressed: onFullSync,
                enabled: !_busy,
                loading: activeOperation == DeveloperOperation.fullSync,
                iconColor: context.appColors.warning,
              ),
              divider,
              _ActionRow(
                icon: Icons.radar_rounded,
                label: t.developer_action_rescan,
                subtitle: 'Onchain swaps',
                tooltip: t.developer_action_rescan_tooltip,
                onPressed: onRescan,
                enabled: !_busy,
                loading: activeOperation == DeveloperOperation.rescan,
              ),
            ],
          ),
        ),
        SettingsGlassSection(
          title: t.developer_section_diagnostics,
          child: Column(
            children: [
              _ActionRow(
                icon: Icons.article_outlined,
                label: t.developer_action_view_logs,
                subtitle: 'Live viewer',
                tooltip: t.developer_action_view_logs_tooltip,
                onPressed: onViewLogs,
                enabled: !_busy,
                showChevron: true,
              ),
              divider,
              _ActionRow(
                icon: Icons.ios_share_rounded,
                label: t.developer_action_export,
                subtitle: 'Share / email ZIP',
                tooltip: t.developer_action_export_tooltip,
                onPressed: onExportLogs,
                enabled: !_busy,
                loading: activeOperation == DeveloperOperation.exportLogs,
              ),
              divider,
              _ActionRow(
                icon: Icons.delete_sweep_outlined,
                label: t.developer_action_clear_logs,
                subtitle: 'Memory · DB · files',
                tooltip: t.developer_action_clear_logs_tooltip,
                onPressed: onClearLogs,
                enabled: !_busy,
                loading: activeOperation == DeveloperOperation.clearLogs,
                iconColor: context.colors.negativeColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One action row: icon, label and subtitle, and a spinner while the
/// action runs.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.tooltip,
    required this.onPressed,
    this.enabled = true,
    this.loading = false,
    this.iconColor,
    this.showChevron = false,
  });

  static const double _padding = 16;
  static const double _iconSize = 22;
  static const double _iconGap = 16;

  /// Distance from the panel edge to the row text. Dividers start here.
  static const double textInset = _padding + _iconSize + _iconGap;

  final IconData icon;
  final String label;
  final String subtitle;
  final String tooltip;
  final VoidCallback onPressed;
  final bool enabled;
  final bool loading;

  /// Status color of the icon, for a heavy or destructive action.
  final Color? iconColor;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tt = context.textTheme;
    final active = enabled && !loading;
    final dimmed = !enabled && !loading;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: active ? onPressed : null,
        child: AnimatedOpacity(
          duration: Motion.of(context, Motion.durationFast),
          curve: Motion.curveMove,
          opacity: dimmed ? 0.4 : 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _padding,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: _iconSize,
                    color: iconColor ?? colors.textPrimary,
                  ),
                  const SizedBox(width: _iconGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: tt.bodyLarge?.copyWith(
                            color: colors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: tt.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: Motion.of(context, Motion.durationFast),
                    child: loading
                        ? SizedBox(
                            key: const ValueKey('spinner'),
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.colorScheme.primary,
                            ),
                          )
                        : showChevron
                        ? Icon(
                            Icons.chevron_right_rounded,
                            key: const ValueKey('chevron'),
                            size: 22,
                            color: colors.textSecondary,
                          )
                        : const SizedBox.shrink(key: ValueKey('none')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
