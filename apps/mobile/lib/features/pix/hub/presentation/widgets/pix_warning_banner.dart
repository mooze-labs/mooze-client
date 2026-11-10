import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Explains why a step of the send flow cannot go on.
///
/// It sits on the page, not in a glass panel: a tinted banner with an alert
/// icon, so the warning never depends on color alone. Unlike a snack bar, it
/// stays while the user fixes the input.
class PixWarningBanner extends StatelessWidget {
  final String message;

  const PixWarningBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final color = context.appColors.warning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PixIcon(PixIcons.warning, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
