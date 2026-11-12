import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_notice_sheet.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/glass_info_sheet.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Explains the Pix payment limits in a floating glass sheet.
///
/// The initial and the maximum limits show as label and value rows, split
/// by hairlines.
class PixLimitsInfoSheet extends StatelessWidget {
  const PixLimitsInfoSheet({super.key, this.mustRead = true});

  /// True when the app shows the sheet on its own, after the first-access
  /// notice. The user then reads it before going on: a tap outside or a
  /// drag does not close it, and the button unlocks after the reading time.
  ///
  /// False when the user opened it to read. It then closes at once: by its
  /// button, a tap outside, or a drag.
  final bool mustRead;

  static Future<void> show(BuildContext context, {bool mustRead = true}) {
    return showFloatingGlassSheet<void>(
      context,
      dismissible: !mustRead,
      builder: (context) => PixLimitsInfoSheet(mustRead: mustRead),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final hairline = Divider(
      height: 1,
      thickness: 1,
      color: AppSurfaces.hairline(context),
    );

    return PixNoticeSheet(
      // The same icon as the limits row of the Pix area.
      icon: PixIcons.shieldCheck,
      title: t.pix_limits_title,
      intro: t.pix_limits_intro,
      actionLabel: t.common_understood,
      onAction: () => Navigator.of(context).pop(),
      readingSeconds: mustRead ? PixNoticeSheet.noticeReadingSeconds : 0,
      countingLabel: t.pix_limits_button_understood_countdown,
      dismissible: !mustRead,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          hairline,
          _LimitRow(
            label: t.pix_limits_initial_label,
            value: t.pix_limits_initial_value,
          ),
          hairline,
          _LimitRow(
            label: t.pix_limits_max_label,
            value: t.pix_limits_max_value,
          ),
          hairline,
          const SizedBox(height: 16),
          Text(
            t.pix_limits_explanation,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          PixNoticeNote(icon: PixIcons.level, text: t.pix_limits_trust_info),
          const SizedBox(height: 12),
          PixNoticeNote(
            icon: PixIcons.trendingUp,
            text: t.pix_limits_increase_info,
          ),
        ],
      ),
    );
  }
}

/// A limit as a label on the left and its value on the right.
///
/// The value uses tabular figures. Both wrap when they do not fit on one
/// line.
class _LimitRow extends StatelessWidget {
  const _LimitRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: MergeSemantics(
        child: Row(
          // The label starts on the left and the value ends on the right.
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: context.textTheme.titleSmall?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
