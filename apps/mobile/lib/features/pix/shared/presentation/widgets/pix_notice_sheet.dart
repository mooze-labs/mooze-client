import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/glass_info_sheet.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// A Pix notice in a floating glass sheet: an icon well, a title, an intro,
/// the [body], and one button.
///
/// The body scrolls when it does not fit, and the button stays visible
/// below it. Open it with `showFloatingGlassSheet`, as the L-BTC notice of
/// the send screen.
///
/// With [readingSeconds] above zero, the button unlocks after that many
/// seconds and shows the seconds left with [countingLabel]. Use it only for
/// a notice the app shows on its own, so the user reads it before going on.
/// A notice the user opened to read closes at once, and sets [dismissible].
class PixNoticeSheet extends StatefulWidget {
  const PixNoticeSheet({
    super.key,
    required this.icon,
    this.tone = PixTone.neutral,
    required this.title,
    required this.intro,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    this.readingSeconds = 0,
    this.countingLabel,
    this.dismissible = false,
  }) : assert(
         readingSeconds == 0 || countingLabel != null,
         'A reading time needs a countingLabel',
       );

  /// Reading time of a notice the app shows on its own, in seconds.
  static const int noticeReadingSeconds = 7;

  final PixIconData icon;

  /// Tone of the icon well. A warning notice uses [PixTone.warning].
  final PixTone tone;

  final String title;

  /// Short text below the title.
  final String intro;

  /// Content below the intro.
  final Widget body;

  /// Label of the button once it is unlocked.
  final String actionLabel;
  final VoidCallback onAction;

  /// Seconds before the button unlocks. Zero unlocks it at once.
  final int readingSeconds;

  /// Label of the button while it is locked, with the seconds left.
  final String Function(int seconds)? countingLabel;

  /// True when a tap outside or a drag closes the sheet. Pass the same value
  /// to `showFloatingGlassSheet`. The sheet then shows a drag handle on top,
  /// where a drag moves the sheet and not the body.
  final bool dismissible;

  @override
  State<PixNoticeSheet> createState() => _PixNoticeSheetState();
}

class _PixNoticeSheetState extends State<PixNoticeSheet> {
  late int _secondsLeft = widget.readingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (_secondsLeft > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _secondsLeft--);
        if (_secondsLeft == 0) timer.cancel();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Returns the title style. With large text, the title drops one step,
  /// so long words fit the sheet width without a break.
  static TextStyle? _titleStyle(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(1) > 1.5
      ? context.textTheme.titleMedium
      : context.textTheme.titleLarge;

  @override
  Widget build(BuildContext context) {
    final ready = _secondsLeft == 0;

    return GlassSheet(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      // The icon well starts 28 pt below the top of the glass, with or
      // without the handle.
      padding: EdgeInsets.fromLTRB(8, widget.dismissible ? 10 : 28, 8, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.dismissible) ...[
            const GlassSheetHandle(),
            const SizedBox(height: 14),
          ],
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: PixIconWell(
                      icon: widget.icon,
                      tone: widget.tone,
                      size: 56,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Semantics(
                    header: true,
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: _titleStyle(context)?.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.intro,
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  widget.body,
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PrimaryButton(
              text: ready
                  ? widget.actionLabel
                  : widget.countingLabel!(_secondsLeft),
              isEnabled: ready,
              onPressed: ready ? widget.onAction : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// A secondary note of a Pix notice, with a small leading icon.
class PixNoticeNote extends StatelessWidget {
  const PixNoticeNote({super.key, required this.icon, required this.text});

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
