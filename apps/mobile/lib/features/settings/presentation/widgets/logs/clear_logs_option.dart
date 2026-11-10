import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// One choice of [ClearLogsDialog]: a row that pops the dialog with [value].
///
/// The row has no card of its own; the dialog groups the rows in one glass
/// panel and splits them with hairlines. [iconColor] marks a destructive
/// choice; otherwise the icon is muted.
class ClearOption extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String value;
  final Color? iconColor;

  const ClearOption({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;
    final effectiveIconColor = iconColor ?? colors.textSecondary;

    return InkWell(
      onTap: () => Navigator.pop(context, value),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: effectiveIconColor, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(
                        color: iconColor ?? colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
