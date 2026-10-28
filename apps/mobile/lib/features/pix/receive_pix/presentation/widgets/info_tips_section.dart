import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/motion/fade_slide_in.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Data model for a single info tip. Keep it immutable so tips can live as
/// compile-time constants and are trivially replaceable with a dynamic source.
///
/// Give a [pixIcon] for the Pix icon set. [icon] stays for callers that
/// still pass a Material icon. A tip needs one of the two.
class InfoTip {
  final IconData? icon;
  final PixIconData? pixIcon;
  final String text;

  /// Color of the icon. Null draws a neutral icon.
  final Color? iconColor;

  const InfoTip({this.icon, this.pixIcon, required this.text, this.iconColor})
    : assert(icon != null || pixIcon != null, 'A tip needs an icon.');
}

// ---------------------------------------------------------------------------
// Default tips for the PIX deposit flow, built from localized strings.
// Each item combines a reassurance or rule into one concise sentence.
// Extend or swap this list for dynamic/remote content in the future.
// ---------------------------------------------------------------------------
List<InfoTip> _defaultPixDepositTips(AppLocalizations t) => [
  InfoTip(pixIcon: PixIcons.info, text: t.pix_tip_consecutive_daily),
  InfoTip(pixIcon: PixIcons.shield, text: t.pix_tip_outside_rules_returned),
  InfoTip(pixIcon: PixIcons.clock, text: t.pix_tip_processing_avg_time),
];

/// Maximum number of tips shown by default. Keeps the screen uncluttered
/// while the full list stays ready for future dynamic display.
const _defaultMaxTips = 3;

// ---------------------------------------------------------------------------
// Section widget
// ---------------------------------------------------------------------------

/// Displays concise reassurance tips as secondary text.
///
/// The tips are fine print, so they have no card of their own: each tip is a
/// small icon and a line of secondary text. The section can sit on the page
/// or inside a glass panel.
///
/// The section fades in with a small rise when it first appears. With
/// reduced motion it appears at once. Accepts an optional [tips] override and
/// [maxTips] cap so the caller can control content without touching this
/// file.
class InfoTipsSection extends StatefulWidget {
  /// Override the default static tip list (e.g. from a remote config).
  final List<InfoTip>? tips;

  /// Maximum number of tips to render. Defaults to [_defaultMaxTips].
  final int maxTips;

  const InfoTipsSection({super.key, this.tips, this.maxTips = _defaultMaxTips});

  @override
  State<InfoTipsSection> createState() => _InfoTipsSectionState();
}

class _InfoTipsSectionState extends State<InfoTipsSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.durationBase,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Motion.curveEnter,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isDismissed) {
      if (Motion.isReduced(context)) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final visibleTips = (widget.tips ?? _defaultPixDepositTips(t))
        .take(widget.maxTips)
        .toList();

    return FadeSlideIn(
      animation: _animation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < visibleTips.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            InfoTipItem(tip: visibleTips[i]),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single tip row
// ---------------------------------------------------------------------------

/// Renders one tip: a small icon on the left and short secondary text on the
/// right. Fully reusable — pass any [InfoTip] instance.
class InfoTipItem extends StatelessWidget {
  final InfoTip tip;

  const InfoTipItem({super.key, required this.tip});

  static const double _iconSize = 16;

  @override
  Widget build(BuildContext context) {
    final color = tip.iconColor ?? context.colors.textSecondary;
    final pixIcon = tip.pixIcon;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          // The icon lines up with the first line of text.
          padding: const EdgeInsets.only(top: 1),
          child: pixIcon != null
              ? PixIcon(pixIcon, size: _iconSize, color: color)
              : Icon(tip.icon, size: _iconSize, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            tip.text,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
