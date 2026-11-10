import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/legal_document/legal_document_section.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// An expandable row displaying a single legal document section.
///
/// The row has no surface of its own: the screen stacks the rows in one
/// glass panel and splits them with hairlines.
///
/// [index] is used for the section number. When [showInfoIconForFirst] is
/// true, the first section (index 0) shows an info icon instead of a number.
/// [useMonospaceContent] enables monospace font for the expanded content.
class LegalDocumentExpandableSection extends StatelessWidget {
  final int index;
  final LegalDocumentSection section;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final bool showInfoIconForFirst;
  final bool useMonospaceContent;

  const LegalDocumentExpandableSection({
    super.key,
    required this.index,
    required this.section,
    required this.isExpanded,
    required this.onExpansionChanged,
    this.showInfoIconForFirst = false,
    this.useMonospaceContent = false,
  });

  static const double _badgeWidth = 28;
  static const double _badgeGap = 12;
  static const double _horizontalPadding = 16;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;
    final duration = Motion.of(context, Motion.durationBase);

    final bool isFirstWithIcon = showInfoIconForFirst && index == 0;
    final String badgeText = showInfoIconForFirst ? '$index' : '${index + 1}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: isExpanded,
          child: InkWell(
            onTap: () => onExpansionChanged(!isExpanded),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _horizontalPadding,
                  vertical: 14,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: _badgeWidth,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: isFirstWithIcon
                            ? Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: colors.textSecondary,
                              )
                            : Text(
                                badgeText,
                                style: textTheme.labelLarge?.copyWith(
                                  color: colors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: _badgeGap),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.title,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                              height: 1.35,
                            ),
                          ),
                          AnimatedSize(
                            duration: duration,
                            curve: Motion.curveMove,
                            alignment: Alignment.topLeft,
                            child: isExpanded
                                ? const SizedBox(width: double.infinity)
                                : Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      _getPreview(section.content),
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colors.textSecondary,
                                        height: 1.4,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: duration,
                      curve: Motion.curveMove,
                      child: Icon(
                        Icons.expand_more_rounded,
                        size: 22,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: duration,
          curve: Motion.curveMove,
          alignment: Alignment.topCenter,
          child: isExpanded
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(
                    _horizontalPadding + _badgeWidth + _badgeGap,
                    0,
                    _horizontalPadding,
                    20,
                  ),
                  child: SelectableText(
                    section.content,
                    style:
                        (useMonospaceContent
                                ? textTheme.bodySmall
                                : textTheme.bodyMedium)
                            ?.copyWith(
                              height: 1.6,
                              color: colors.textPrimary.withValues(alpha: 0.86),
                              fontFamily: useMonospaceContent
                                  ? 'monospace'
                                  : null,
                            ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  String _getPreview(String content) {
    return content.length > 100 ? '${content.substring(0, 100)}...' : content;
  }
}
