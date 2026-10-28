import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Explains the Pix payment limits, after the first-access notice.
///
/// The initial and the maximum limits show as label and value rows, split
/// by hairlines. The button unlocks after a short countdown.
class PixLimitsInfoDialog extends StatefulWidget {
  const PixLimitsInfoDialog({super.key});

  @override
  State<PixLimitsInfoDialog> createState() => _PixLimitsInfoDialogState();

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PixLimitsInfoDialog(),
    );
  }
}

class _PixLimitsInfoDialogState extends State<PixLimitsInfoDialog> {
  int _secondsRemaining = 7;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Returns the title style. With large text, the title drops one step,
  /// so long words fit the dialog width without a break.
  static TextStyle? _titleStyle(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(1) > 1.5
      ? context.textTheme.titleMedium
      : context.textTheme.titleLarge;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final bool isButtonEnabled = _secondsRemaining == 0;
    final hairline = Divider(
      height: 1,
      thickness: 1,
      color: AppSurfaces.hairline(context),
    );

    return GlassAlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The same icon as the limits row of the Pix area.
          const PixIconWell(icon: PixIcons.shieldCheck, size: 48),
          const SizedBox(height: 16),
          Text(
            t.pix_limits_title,
            style: _titleStyle(context)?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              height: 1.25,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.pix_limits_intro,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
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
            _NoteRow(icon: PixIcons.level, text: t.pix_limits_trust_info),
            const SizedBox(height: 12),
            _NoteRow(
              icon: PixIcons.trendingUp,
              text: t.pix_limits_increase_info,
            ),
          ],
        ),
      ),
      actions: [
        PrimaryButton(
          text: isButtonEnabled
              ? t.common_understood
              : t.pix_limits_button_understood_countdown(_secondsRemaining),
          isEnabled: isButtonEnabled,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
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

/// A secondary note with a small leading icon.
class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.icon, required this.text});

  final PixIconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.textSecondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          // Aligns the icon with the first line of text.
          padding: const EdgeInsets.only(top: 1),
          child: PixIcon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: context.textTheme.bodySmall?.copyWith(
              color: color,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
