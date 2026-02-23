import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

/// Botão de ação em grid para a tela de desenvolvedor
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
    final theme = Theme.of(context);
    final defaultBgColor = AppColors.swapCardBackground;
    final defaultIconColor = AppColors.primaryColor;
    final defaultTextColor = Colors.white;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color:
                  enabled
                      ? (backgroundColor ?? defaultBgColor)
                      : Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
              boxShadow:
                  enabled
                      ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                      : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color:
                      enabled
                          ? (iconColor ?? defaultIconColor)
                          : Colors.grey[600],
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        enabled
                            ? (textColor ?? defaultTextColor)
                            : Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
