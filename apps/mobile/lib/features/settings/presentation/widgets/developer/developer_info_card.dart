import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mooze_mobile/features/settings/presentation/widgets/settings/settings_glass_section.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/app_snackbar.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// System information of the developer screen.
///
/// Two glass groups: the runtime rows with the log counters, then the SDK
/// versions. Rows are split by hairlines.
class DeveloperInfoCard extends StatelessWidget {
  const DeveloperInfoCard({
    super.key,
    required this.appVersion,
    required this.buildNumber,
    required this.lwkVersion,
    required this.bdkVersion,
    required this.bitcoinTip,
    required this.totalLogs,
    required this.dbLogs,
    required this.logRetention,
    required this.onViewLogs,
  });

  final String appVersion;
  final String buildNumber;
  final String lwkVersion;
  final String bdkVersion;
  final int? bitcoinTip;
  final int totalLogs;
  final int dbLogs;
  final String logRetention;
  final VoidCallback onViewLogs;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final hasTip = bitcoinTip != null && bitcoinTip! > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGlassSection(
          title: t.developer_system_info,
          child: Column(
            children: [
              _InfoRow(
                label: t.developer_app_version,
                value: appVersion,
                detail: 'build $buildNumber',
                copyText: '$appVersion ($buildNumber)',
              ),
              const PanelDivider(indent: _InfoRow.padding),
              _InfoRow(
                label: t.developer_bitcoin_tip,
                value: hasTip
                    ? '#${_formatInt(bitcoinTip!)}'
                    : t.developer_unavailable,
                muted: !hasTip,
                copyText: hasTip ? bitcoinTip.toString() : null,
              ),
              const PanelDivider(),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _StatCell(
                        label: t.developer_logs_memory,
                        value: _compactNumber(totalLogs),
                        onTap: onViewLogs,
                      ),
                    ),
                    const _VerticalHairline(),
                    Expanded(
                      child: _StatCell(
                        label: t.developer_logs_db,
                        value: _compactNumber(dbLogs),
                      ),
                    ),
                    const _VerticalHairline(),
                    Expanded(
                      child: _StatCell(
                        label: t.developer_log_retention_label,
                        value: logRetention,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SettingsGlassSection(
          title: 'SDK versions',
          child: Column(
            children: [
              _InfoRow(label: 'LWK', value: lwkVersion),
              const PanelDivider(indent: _InfoRow.padding),
              _InfoRow(label: 'BDK', value: bdkVersion),
            ],
          ),
        ),
      ],
    );
  }

  static String _compactNumber(int v) {
    if (v < 1000) return v.toString();
    if (v < 1000000) return '${(v / 1000).toStringAsFixed(v < 10000 ? 1 : 0)}k';
    return '${(v / 1000000).toStringAsFixed(1)}M';
  }
}

String _formatInt(int v) {
  final s = v.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final rem = s.length - i;
    buf.write(s[i]);
    if (rem > 1 && rem % 3 == 1) buf.write(',');
  }
  return buf.toString();
}

/// A label and value row. The muted label sits on the left, the value on
/// the right, with an optional copy button.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.detail,
    this.copyText,
    this.muted = false,
  });

  static const double padding = 16;

  final String label;
  final String value;

  /// Muted text after the value, for example the build number.
  final String? detail;
  final String? copyText;

  /// Shows the value in the muted color, for a missing value.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tt = context.textTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: EdgeInsets.only(
          left: padding,
          right: copyText != null ? 4 : padding,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: tt.bodyMedium?.copyWith(color: colors.textSecondary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Text.rich(
                TextSpan(
                  text: value,
                  style: tt.bodyMedium?.copyWith(
                    color: muted ? colors.textSecondary : colors.textPrimary,
                    fontWeight: muted ? FontWeight.w400 : FontWeight.w500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  children: [
                    if (detail != null)
                      TextSpan(
                        text: '  $detail',
                        style: tt.bodySmall?.copyWith(
                          color: colors.textSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ),
            if (copyText != null) _CopyButton(text: copyText!, label: label),
          ],
        ),
      ),
    );
  }
}

/// One log counter of the stat strip at the bottom of the system panel.
class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tt = context.textTheme;

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  value,
                  style: tt.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: colors.textSecondary,
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: tt.bodySmall?.copyWith(
              color: colors.textSecondary,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
  }
}

class _VerticalHairline extends StatelessWidget {
  const _VerticalHairline();

  @override
  Widget build(BuildContext context) {
    return VerticalDivider(
      width: 1,
      thickness: 1,
      indent: 12,
      endIndent: 12,
      color: AppSurfaces.hairline(context),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.text, required this.label});

  final String text;
  final String label;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        Clipboard.setData(ClipboardData(text: text));
        AppSnackBar.info(context, '$label copied');
      },
      tooltip: MaterialLocalizations.of(context).copyButtonLabel,
      icon: Icon(
        Icons.content_copy_rounded,
        size: 16,
        color: context.colors.textSecondary,
      ),
    );
  }
}
