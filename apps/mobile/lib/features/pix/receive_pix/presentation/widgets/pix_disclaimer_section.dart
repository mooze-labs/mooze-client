import 'package:flutter/material.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Small-print disclaimer shown above the slide-to-confirm button on the
/// PIX confirmation screen. Contains a compact fee table and usage rules.
///
/// Deliberately low-emphasis — it is supplementary fine print, not a CTA.
class PixDisclaimerSection extends StatelessWidget {
  const PixDisclaimerSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = context.colorScheme;
    final dimColor = colorScheme.onSurface.withValues(alpha: 0.42);
    final warnColor = context.appColors.warning.withValues(alpha: 0.65);

    final dimStyle = context.textTheme.labelSmall?.copyWith(
      color: dimColor,
      height: 1.55,
    );
    final boldDimStyle = dimStyle?.copyWith(fontWeight: FontWeight.w600);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Rules ─────────────────────────────────────────────────────────
        Text(t.pix_disclaimer_header, style: boldDimStyle),
        const SizedBox(height: 4),
        _BulletItem(
          text: t.pix_disclaimer_max_consecutive,
          style: dimStyle,
        ),
        _BulletItem(
          text: t.pix_disclaimer_daily_limit,
          style: dimStyle,
        ),
        const SizedBox(height: 8),
        // ── Warnings ──────────────────────────────────────────────────────
        _WarningItem(
          text: t.pix_disclaimer_outside_rules,
          style: dimStyle,
          iconColor: warnColor,
        ),
        const SizedBox(height: 3),
        _WarningItem(
          text: t.pix_disclaimer_analyzed,
          style: dimStyle,
          iconColor: warnColor,
        ),
        const SizedBox(height: 3),
        _WarningItem(
          text: t.pix_disclaimer_avg_time,
          style: dimStyle,
          iconColor: warnColor,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

class _FeeTableRow extends StatelessWidget {
  final String range;
  final String fee;
  final TextStyle? style;
  final TextStyle? feeStyle;

  const _FeeTableRow({
    required this.range,
    required this.fee,
    required this.style,
    required this.feeStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(range, style: style)),
        Text('·', style: style),
        const SizedBox(width: 6),
        Text(fee, style: feeStyle),
      ],
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const _BulletItem({required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5, right: 6),
            child: Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                color: style?.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}

class _WarningItem extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color iconColor;

  const _WarningItem({
    required this.text,
    required this.style,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1, right: 5),
          child: Icon(Icons.warning_amber_rounded, size: 12, color: iconColor),
        ),
        Expanded(child: Text(text, style: style)),
      ],
    );
  }
}
