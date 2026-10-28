import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Placeholder shown when a hub list has nothing to display.
///
/// An icon well, a short title, an optional message, and an optional way
/// forward. It never fills the space with decoration.
class PixEmptyState extends StatelessWidget {
  final PixIconData icon;
  final String title;
  final String? message;

  /// Label of the optional recovery action.
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Reduces the paddings for use inside a card.
  final bool isCompact;

  const PixEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isCompact ? 20 : 36,
      ),
      child: Column(
        children: [
          PixIconWell(icon: icon, size: isCompact ? 44 : 56),
          SizedBox(height: isCompact ? 12 : 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: context.textTheme.labelLarge?.copyWith(
                  color: context.colors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
