import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/shared/widgets/glass/glass_sheet_badge.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/press_scale.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// A glass banner for a service status that needs the user, for example a
/// failed sync: the badge of the status, a title, a message, and a chevron.
/// A tap opens the details of the status.
///
/// With [onDismiss], a close button takes the place of the chevron, for a
/// notice the user can put away, such as a new version of the app. The
/// close button is its own control for screen readers.
///
/// The badge carries the tone of the status. The text keeps the primary and
/// secondary text colors, so it stays readable on the glass.
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.onTap,
    this.onDismiss,
    this.dismissTooltip,
  }) : assert(
         (onDismiss == null) == (dismissTooltip == null),
         'Give both onDismiss and dismissTooltip, or neither',
       );

  final PixIconData icon;

  /// The tone of the status, for example the warning or the error color.
  final Color color;

  final String title;
  final String message;
  final VoidCallback onTap;

  /// Puts the banner away. Null shows a chevron instead of a close button.
  final VoidCallback? onDismiss;

  /// Label of the close button.
  final String? dismissTooltip;

  @override
  Widget build(BuildContext context) {
    final onDismiss = this.onDismiss;
    return PressScale(
      child: GlassPanel(
        child: Row(
          children: [
            Expanded(
              child: MergeSemantics(
                child: Semantics(
                  button: true,
                  child: InkWell(
                    onTap: onTap,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        12,
                        12,
                        onDismiss == null ? 14 : 4,
                        12,
                      ),
                      child: Row(
                        children: [
                          GlassSheetBadge(icon: icon, color: color),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.textTheme.bodyMedium?.copyWith(
                                    color: context.colors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  message,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: context.colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (onDismiss == null) ...[
                            const SizedBox(width: 8),
                            PixIcon(
                              PixIcons.chevronRight,
                              size: 18,
                              color: context.colors.textTertiary,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (onDismiss != null)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: IconButton(
                  tooltip: dismissTooltip,
                  onPressed: onDismiss,
                  icon: PixIcon(
                    PixIcons.close,
                    size: 18,
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
