import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_surface_card.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// One line of a review summary.
class PixSummaryEntry {
  final String label;
  final String value;

  /// Draws the value with the emphasis used for the amount.
  final bool highlight;

  const PixSummaryEntry(this.label, this.value, {this.highlight = false});
}

/// Glass panel that lists the details of a payment.
///
/// Each detail is a label on the left and its value on the right, split by
/// hairlines. Values use tabular figures, so amounts line up. The
/// highlighted entry, usually the amount, has a larger and bolder value.
class PixSummaryCard extends StatelessWidget {
  final List<PixSummaryEntry> entries;

  const PixSummaryCard({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    return PixSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Column(
        children: [
          for (var index = 0; index < entries.length; index++) ...[
            if (index > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: AppSurfaces.hairline(context),
              ),
            _SummaryRow(entry: entries[index]),
          ],
        ],
      ),
    );
  }
}

/// A label and its value on one line.
///
/// A long label or value wraps instead of overflowing. The summaries show
/// long values, such as a request ID.
class _SummaryRow extends StatelessWidget {
  final PixSummaryEntry entry;

  const _SummaryRow({required this.entry});

  /// Largest part of the row that the value can take.
  static const double _maxValueShare = 0.6;

  /// Text scale from which the label goes above the value.
  static const double _stackedTextScale = 1.5;

  @override
  Widget build(BuildContext context) {
    final valueStyle =
        (entry.highlight
                ? context.textTheme.titleMedium
                : context.textTheme.bodyMedium)
            ?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: entry.highlight ? FontWeight.w700 : FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
            );
    final label = Text(
      entry.label,
      style: context.textTheme.bodyMedium?.copyWith(
        color: context.colors.textSecondary,
      ),
    );
    // With very large text, a label beside its value has too little width
    // and breaks inside words. The label then goes above the value.
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    if (textScale >= _stackedTextScale) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              label,
              const SizedBox(height: 2),
              Text(entry.value, style: valueStyle),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: MergeSemantics(
        // The label takes the space that the value leaves. The value takes
        // its own width up to [_maxValueShare] of the row and ends on the
        // right. So a short value never squeezes the label, and a long
        // value, such as an ID, wraps.
        child: LayoutBuilder(
          builder: (context, constraints) => Row(
            crossAxisAlignment: entry.highlight
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Expanded(child: label),
              const SizedBox(width: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * _maxValueShare,
                ),
                child: Text(
                  entry.value,
                  textAlign: TextAlign.end,
                  style: valueStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
