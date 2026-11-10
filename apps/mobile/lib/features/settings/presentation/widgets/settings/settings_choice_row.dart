import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/settings/label_settings.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// One option of a single-choice list inside a settings panel, such as a
/// language.
///
/// It has the layout of a [LabelSettings] row: an optional [leading] icon
/// in the icon slot, the [title], and an optional [subtitle]. The selected
/// option shows a check at the end. The check is the only brand color of
/// the list, so the choice reads at a glance.
class SettingsChoiceRow extends StatelessWidget {
  const SettingsChoiceRow({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.leading,
  });

  final String title;
  final String? subtitle;

  /// Icon of the option, at most [LabelSettings.iconSize] wide.
  final Widget? leading;

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final duration = Motion.of(context, Motion.durationFast);
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LabelSettings.horizontalPadding,
                vertical: 12,
              ),
              child: Row(
                children: [
                  if (leading != null) ...[
                    SizedBox.square(
                      dimension: LabelSettings.iconSize,
                      child: Center(child: leading),
                    ),
                    const SizedBox(width: LabelSettings.iconGap),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: context.textTheme.bodyLarge?.copyWith(
                            color: context.colors.textPrimary,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: context.colors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedSwitcher(
                    duration: duration,
                    switchInCurve: Motion.curveEnter,
                    switchOutCurve: Motion.curveExit,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    ),
                    child: selected
                        ? Icon(
                            Icons.check_rounded,
                            key: const ValueKey('selected'),
                            size: 22,
                            color: context.colorScheme.primary,
                          )
                        : const SizedBox.square(
                            key: ValueKey('unselected'),
                            dimension: 22,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
