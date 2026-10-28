import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// One segment of [MerchantSegmentedTabs].
class MerchantSegment {
  const MerchantSegment({required this.icon, required this.label, this.key});

  final IconData icon;
  final String label;

  /// Key of the segment, for example a tutorial target.
  final Key? key;
}

/// A glass capsule that switches the tabs of [controller].
///
/// A glass lens marks the selected segment. The lens follows the tab
/// animation, so it also slides while the user swipes the tab view. A tap
/// moves it over [Motion.durationEmphasis]. With reduced motion, it jumps.
///
/// The selected segment has the primary text color and a bold label, and
/// screen readers read it as selected, so the choice never depends on the
/// lens alone.
class MerchantSegmentedTabs extends StatelessWidget {
  const MerchantSegmentedTabs({
    super.key,
    required this.controller,
    required this.segments,
  }) : assert(segments.length > 1);

  final TabController controller;
  final List<MerchantSegment> segments;

  /// Smallest height of the capsule. It is also the touch target.
  static const double minHeight = 48;

  /// Space between the capsule edge and the lens.
  static const double _inset = 4;

  void _select(BuildContext context, int index) {
    controller.animateTo(
      index,
      duration: Motion.of(context, Motion.durationEmphasis),
      curve: Motion.curveMove,
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = segments.length;
    final animation = controller.animation!;

    return LiquidGlass(
      blurBackdrop: false,
      child: Padding(
        padding: const EdgeInsets.all(_inset),
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final position = animation.value.clamp(0.0, count - 1.0);
            final selected = position.round();
            return Stack(
              children: [
                Positioned.fill(
                  child: Align(
                    alignment: Alignment(-1 + 2 * position / (count - 1), 0),
                    child: FractionallySizedBox(
                      widthFactor: 1 / count,
                      heightFactor: 1,
                      child: const GlassLens(),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var index = 0; index < count; index++)
                      Expanded(
                        child: _Segment(
                          key: segments[index].key,
                          segment: segments[index],
                          selected: index == selected,
                          onTap: () => _select(context, index),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    super.key,
    required this.segment,
    required this.selected,
    required this.onTap,
  });

  final MerchantSegment segment;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? context.colors.textPrimary
        : context.colors.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: segment.label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight:
                MerchantSegmentedTabs.minHeight -
                MerchantSegmentedTabs._inset * 2,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(segment.icon, size: 18, color: color),
                    const SizedBox(width: 8),
                    Text(
                      segment.label,
                      style: context.textTheme.labelLarge?.copyWith(
                        color: color,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
