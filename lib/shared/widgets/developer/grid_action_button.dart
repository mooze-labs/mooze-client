import 'package:flutter/material.dart';

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
    final colorScheme = theme.colorScheme;
    final defaultBgColor = colorScheme.surfaceContainer;
    final defaultIconColor = colorScheme.primary;
    final defaultTextColor = colorScheme.onSurface;

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
                      : colorScheme.outline,
              borderRadius: BorderRadius.circular(12),
              boxShadow:
                  enabled
                      ? [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.2),
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
                          : colorScheme.outlineVariant,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        enabled
                            ? (textColor ?? defaultTextColor)
                            : colorScheme.outlineVariant,
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
