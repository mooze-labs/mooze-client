import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The tone of an [ImportStatusNote].
enum ImportStatusTone { positive, warning, negative }

/// A short status of the typed phrase, in a tinted panel: a valid phrase, a
/// failed checksum, or an input error.
///
/// The tint and the icon carry the tone. The text keeps the primary text
/// color, so it keeps its contrast and the status never depends on color
/// alone.
class ImportStatusNote extends StatelessWidget {
  const ImportStatusNote({super.key, required this.tone, required this.text});

  final ImportStatusTone tone;
  final String text;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (tone) {
      ImportStatusTone.positive => (
        context.colors.positiveColor,
        Icons.check_circle_rounded,
      ),
      ImportStatusTone.warning => (
        context.appColors.warning,
        Icons.warning_amber_rounded,
      ),
      ImportStatusTone.negative => (
        context.colors.negativeColor,
        Icons.error_outline_rounded,
      ),
    };
    // The light page is bright, so a weaker tint gives the same weight.
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.10 : 0.08),
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
