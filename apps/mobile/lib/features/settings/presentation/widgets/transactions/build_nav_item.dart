import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/shared/widgets/motion/press_scale.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// One tab of a floating glass navigation capsule: an icon above its label.
///
/// The tab fills the slot that its parent gives it, so the whole slot is
/// the touch target. The selected tab takes the brand color on its icon and
/// the primary text color on its label; the glass lens under it is drawn by
/// the capsule.
class AppNavItem extends StatelessWidget {
  final String icon;
  final String label;
  final int index;
  final int currentIndex;
  final VoidCallback onTap;

  const AppNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  /// Height of the label line. A large text scale shrinks the label instead
  /// of growing past the capsule.
  static const double _labelLine = 16;

  bool get isSelected => currentIndex == index;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final iconColor = isSelected ? colors.primaryColor : colors.textSecondary;
    final duration = Motion.of(context, Motion.durationFast);

    // `excludeSemantics` drops the semantics of the gesture below, so the
    // node carries the tap action itself.
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: PressScale(
          scale: Motion.pressScaleCircle,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: iconColor),
                  duration: duration,
                  curve: Motion.curveMove,
                  builder: (context, color, _) => SvgPicture.asset(
                    icon,
                    width: 22,
                    height: 22,
                    colorFilter: ColorFilter.mode(
                      color ?? iconColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  height: _labelLine,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AnimatedDefaultTextStyle(
                      duration: duration,
                      curve: Motion.curveMove,
                      style: (context.textTheme.labelSmall ?? const TextStyle())
                          .copyWith(
                            color: isSelected
                                ? colors.textPrimary
                                : colors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                      child: Text(label, maxLines: 1, softWrap: false),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
