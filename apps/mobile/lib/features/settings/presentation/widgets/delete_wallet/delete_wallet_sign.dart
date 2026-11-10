import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// A risk the user confirms before deleting the wallet, as a row of a
/// glass panel: a title, a muted description, and a check.
///
/// The check is a hairline ring until the user taps the row. It then fills
/// with the brand color, the only accent of the row.
class DeleteWalletSign extends StatelessWidget {
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const DeleteWalletSign({
    super.key,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  static const double _checkSize = 24;

  @override
  Widget build(BuildContext context) {
    final primary = context.colorScheme.primary;
    final duration = Motion.of(context, Motion.durationFast);

    return Semantics(
      checked: isSelected,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.textTheme.bodyLarge?.copyWith(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                AnimatedContainer(
                  duration: duration,
                  curve: Motion.curveMove,
                  width: _checkSize,
                  height: _checkSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? primary
                          : AppSurfaces.hairline(context),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: context.colorScheme.onPrimary,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
