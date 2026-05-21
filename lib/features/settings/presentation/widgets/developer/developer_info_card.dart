import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';


class DeveloperInfoCard extends StatelessWidget {
  const DeveloperInfoCard({
    super.key,
    required this.appVersion,
    required this.buildNumber,
    required this.lwkVersion,
    required this.bdkVersion,
    required this.breezVersion,
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
  final String breezVersion;
  final int? bitcoinTip;
  final int totalLogs;
  final int dbLogs;
  final String logRetention;
  final VoidCallback onViewLogs;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final extra = context.appColors;
    final tt = context.textTheme;
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
              Icon(Icons.memory_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 10),
              Text(
                t.developer_system_info,
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _RuntimeRow(
            label: t.developer_app_version,
            value: appVersion,
            trailing: _Chip(text: 'build $buildNumber'),
            copyText: '$appVersion ($buildNumber)',
          ),
          const SizedBox(height: 14),
          _SectionLabel(text: 'SDK versions'),
          const SizedBox(height: 8),
          _SdkRow(label: 'LWK', version: lwkVersion),
          const SizedBox(height: 6),
          _SdkRow(label: 'BDK', version: bdkVersion),
          const SizedBox(height: 6),
          _SdkRow(label: 'Breez SDK', version: breezVersion),
          const SizedBox(height: 12),
          _RuntimeRow(
            label: 'Bitcoin tip',
            value: bitcoinTip != null && bitcoinTip! > 0
                ? '#${_formatInt(bitcoinTip!)}'
                : 'unavailable',
            valueColor: bitcoinTip != null && bitcoinTip! > 0
                ? null
                : extra.textSecondary,
            valueWeight: FontWeight.w500,
            copyText: bitcoinTip != null && bitcoinTip! > 0
                ? bitcoinTip.toString()
                : null,
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: cs.onSurface.withValues(alpha: 0.06),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _StatTile(
                  label: t.developer_logs_memory,
                  value: _compactNumber(totalLogs),
                  icon: Icons.memory_rounded,
                  onTap: onViewLogs,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  label: t.developer_logs_db,
                  value: _compactNumber(dbLogs),
                  icon: Icons.storage_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  label: t.developer_log_retention_label,
                  value: logRetention,
                  icon: Icons.history_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
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

class _SdkRow extends StatelessWidget {
  const _SdkRow({required this.label, required this.version});

  final String label;
  final String version;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final extra = context.appColors;
    final tt = context.textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: tt.bodyMedium?.copyWith(
                color: extra.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              version,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuntimeRow extends StatelessWidget {
  const _RuntimeRow({
    required this.label,
    required this.value,
    this.trailing,
    this.copyText,
    this.valueColor,
    this.valueWeight,
  });

  final String label;
  final String value;
  final Widget? trailing;
  final String? copyText;
  final Color? valueColor;
  final FontWeight? valueWeight;

  @override
  Widget build(BuildContext context) {
    final extra = context.appColors;
    final tt = context.textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: tt.bodySmall?.copyWith(
              color: extra.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: valueWeight ?? FontWeight.w600,
                    color: valueColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.end,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
              if (copyText != null) ...[
                const SizedBox(width: 8),
                _CopyButton(text: copyText!, label: label),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final extra = context.appColors;
    final tt = context.textTheme;

    final card = Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: extra.textTertiary),
          const SizedBox(height: 6),
          Text(
            value,
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: tt.bodySmall?.copyWith(
              color: extra.textSecondary,
              fontSize: 11,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: card,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final extra = context.appColors;
    final tt = context.textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: tt.bodySmall?.copyWith(
          color: extra.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.text, required this.label});

  final String text;
  final String label;

  @override
  Widget build(BuildContext context) {
    final extra = context.appColors;
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label copied'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          Icons.content_copy_rounded,
          size: 13,
          color: extra.textTertiary,
        ),
      ),
    );
  }
}
