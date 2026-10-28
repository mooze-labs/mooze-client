import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Row of a Pix list: an icon well, a title, an optional subtitle, and a
/// chevron.
///
/// Put the rows in a [PixSurfaceCard]. Dividers between rows start at the
/// text, at [textInset].
class PixActionTile extends StatelessWidget {
  final PixIconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  /// Extra widget placed before the chevron, such as a badge.
  final Widget? trailing;

  /// Tone of the icon well. Neutral by default.
  final PixTone tone;

  const PixActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.tone = PixTone.neutral,
  });

  static const double _horizontalPadding = 12;
  static const double _gap = 14;

  /// Distance from the row edge to the text.
  static const double textInset =
      _horizontalPadding + PixIconWell.defaultSize + _gap;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _horizontalPadding,
            vertical: 12,
          ),
          child: Row(
            children: [
              PixIconWell(icon: icon, tone: tone),
              const SizedBox(width: _gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
              PixIcon(
                PixIcons.chevronRight,
                size: 18,
                color: context.colors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
