import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Section title with an optional action on the right, for example
/// "See more".
class SectionHeader extends StatelessWidget {
  final VoidCallback? onAction;
  final String title;
  final String? actionDescription;

  const SectionHeader({
    super.key,
    required this.title,
    this.onAction,
    this.actionDescription,
  });

  @override
  Widget build(BuildContext context) {
    final action = onAction;
    final description = actionDescription;
    // The minimum height keeps the same rhythm with and without an action.
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: context.textTheme.titleLarge),
            ),
          ),
          if (action != null && description != null)
            // The text button keeps a 48 pt hit area around the short label.
            TextButton(
              onPressed: action,
              style: TextButton.styleFrom(
                foregroundColor: context.colors.textSecondary,
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                description,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
