import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Notice about the security review of Pix payments, shown on the first
/// access to Pix.
///
/// The accept button unlocks after a short countdown, so the user reads the
/// notice. The dialog returns true when the user accepts.
class FirstTimePixDialog extends StatefulWidget {
  const FirstTimePixDialog({super.key});

  @override
  State<FirstTimePixDialog> createState() => _FirstTimePixDialogState();

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const FirstTimePixDialog(),
    );
  }
}

class _FirstTimePixDialogState extends State<FirstTimePixDialog> {
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
    final isButtonEnabled = _secondsRemaining == 0;

    return GlassAlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // An attention notice: the warning tone, an alert shape, and the
          // title together carry the meaning.
          const PixIconWell(
            icon: PixIcons.shieldAlert,
            tone: PixTone.warning,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            t.pix_first_time_title,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.pix_first_time_description,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            _OutcomeRow(
              icon: PixIcons.clock,
              text: 'a) ${t.pix_first_time_item_completed}',
            ),
            const SizedBox(height: 12),
            _OutcomeRow(
              icon: PixIcons.restart,
              text: 'b) ${t.pix_first_time_item_refunded}',
            ),
            const SizedBox(height: 20),
            Divider(
              height: 1,
              thickness: 1,
              color: AppSurfaces.hairline(context),
            ),
            const SizedBox(height: 16),
            _NoteRow(
              icon: PixIcons.shieldCheck,
              text: t.pix_first_time_security_note,
            ),
          ],
        ),
      ),
      actions: [
        PrimaryButton(
          text: isButtonEnabled
              ? t.pix_first_time_accept_button
              : t.pix_first_time_accept_button_counting(_secondsRemaining),
          isEnabled: isButtonEnabled,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

/// One possible outcome of the review: an icon well and a short text.
class _OutcomeRow extends StatelessWidget {
  const _OutcomeRow({required this.icon, required this.text});

  final PixIconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PixIconWell(icon: icon, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
      ],
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
