import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Copy button at the end of a detail row.
///
/// After a copy the icon turns into a green check for a moment. The swap
/// cross-fades over [Motion.durationFast]. The touch target is 40 pt, the
/// icon 18 pt.
class InlineCopyButton extends StatelessWidget {
  final bool isCopied;
  final VoidCallback onTap;

  const InlineCopyButton({
    super.key,
    required this.isCopied,
    required this.onTap,
  });

  static const double size = 40;

  @override
  Widget build(BuildContext context) {
    final label = MaterialLocalizations.of(context).copyButtonLabel;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: size,
            child: AnimatedSwitcher(
              duration: Motion.of(context, Motion.durationFast),
              switchInCurve: Motion.curveEnter,
              switchOutCurve: Motion.curveExit,
              child: Icon(
                isCopied ? Icons.check_rounded : Icons.copy_rounded,
                key: ValueKey(isCopied),
                size: 18,
                color: isCopied
                    ? context.colors.positiveColor
                    : context.colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
