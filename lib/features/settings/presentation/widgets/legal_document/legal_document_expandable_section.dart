import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/legal_document/legal_document_section.dart';

/// An expandable tile displaying a single legal document section.
///
/// [index] is used for the numbered badge. When [showInfoIconForFirst] is true,
/// the first section (index 0) shows an info icon instead of a number.
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final bool isFirstWithIcon = showInfoIconForFirst && index == 0;
    final String badgeText = showInfoIconForFirst ? '$index' : '${index + 1}';
    final Color badgeColor =
        showInfoIconForFirst ? colorScheme.primaryContainer : colorScheme.primary;
    final Color badgeTextColor =
        showInfoIconForFirst
            ? colorScheme.onPrimaryContainer
            : colorScheme.onPrimary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: isExpanded,
            onExpansionChanged: onExpansionChanged,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: isFirstWithIcon
                    ? Icon(
                        Icons.info_outline_rounded,
                        color: badgeTextColor,
                        size: 18,
                      )
                    : Text(
                        badgeText,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: badgeTextColor,
                        ),
                      ),
              ),
            ),
            title: Text(
              section.title,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              _getPreview(section.content),
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    section.content,
                    style: textTheme.titleSmall?.copyWith(
                      height: 1.6,
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                      fontFamily: useMonospaceContent ? 'monospace' : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPreview(String content) {
    return content.length > 100 ? '${content.substring(0, 100)}...' : content;
  }
}
