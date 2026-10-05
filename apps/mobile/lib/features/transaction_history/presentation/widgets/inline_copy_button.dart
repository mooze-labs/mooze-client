import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Compact animated copy affordance shared by every copyable detail row.
class InlineCopyButton extends StatelessWidget {
  final bool isCopied;
  final VoidCallback onTap;

  const InlineCopyButton({
    super.key,
    required this.isCopied,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final positive = context.colors.positiveColor;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: SizedBox(
            key: ValueKey(isCopied),
            width: 30,
            height: 30,
            child: Icon(
              isCopied ? Icons.check_rounded : Icons.copy_rounded,
              size: 16,
              color: isCopied ? positive : cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}
