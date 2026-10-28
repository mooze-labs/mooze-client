import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Title of a hub section, with an optional trailing action.
///
/// Screen readers announce the title as a heading, so a user can jump from
/// section to section.
class PixSectionHeader extends StatelessWidget {
  final String title;

  /// Label of the trailing action, usually "View all".
  final String? actionLabel;

  final VoidCallback? onAction;

  const PixSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Semantics(
            // Its own node, so only the title is the heading.
            container: true,
            header: true,
            child: Text(
              title,
              style: context.textTheme.titleSmall?.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 40),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              // The visible button stays 40 pt high. The touch target
              // grows to 48 pt.
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
            child: Text(
              actionLabel!,
              style: context.textTheme.labelLarge?.copyWith(
                color: context.colors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
