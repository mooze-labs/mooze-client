import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Action button used inside the developer tools grid
class GridActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;
  final bool enabled;

  const GridActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    final effectiveIconColor = enabled
        ? (iconColor ?? colorScheme.primary)
        : colorScheme.onSurface.withValues(alpha: 0.25);
    final effectiveLabelColor = enabled
        ? (textColor ?? colorScheme.onSurface)
        : colorScheme.onSurface.withValues(alpha: 0.25);
    final effectiveBgColor = enabled
        ? (backgroundColor ?? colorScheme.onSurface.withValues(alpha: 0.04))
        : colorScheme.onSurface.withValues(alpha: 0.02);
    final borderColor = colorScheme.onSurface.withValues(
      alpha: enabled ? 0.08 : 0.04,
    );

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: effectiveBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: effectiveIconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: effectiveIconColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: textTheme.bodySmall?.copyWith(
                      color: effectiveLabelColor,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
