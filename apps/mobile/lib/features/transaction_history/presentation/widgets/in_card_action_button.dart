import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// A link row of the transaction detail screen, for example "View in the
/// explorer".
///
/// It sits inside a glass panel: an icon well on a neutral surface, a
/// title, a subtitle, and an outward arrow at the end, because the link
/// leaves the app. A row without [onPressed] is dimmed and takes no taps.
class InCardActionButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onPressed;

  const InCardActionButton({
    super.key,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onPressed,
  });

  /// Space between the panel edge and the row content.
  static const double horizontalPadding = 16;

  /// Diameter of the icon well.
  static const double wellSize = 40;

  /// Distance from the panel edge to the row text. Dividers start here.
  static const double textInset = horizontalPadding + wellSize + 12;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final body = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 12,
        ),
        child: Row(
          children: [
            Container(
              width: wellSize,
              height: wellSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.colors.actionButtonBackground,
              ),
              child: Icon(icon, size: 20, color: context.colors.textPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.arrow_outward_rounded,
              size: 18,
              color: context.colors.textSecondary,
            ),
          ],
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: InkWell(onTap: onPressed, child: body),
      ),
    );
  }
}
