import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// A titled group of the settings screens: a muted title above a
/// [GlassPanel] that holds the rows.
///
/// The group sits on the 20 pt gutter. The title lines up with the row
/// content inside the panel. The panel has no backdrop blur, because it
/// scrolls over a fixed background.
class SettingsGlassSection extends StatelessWidget {
  const SettingsGlassSection({
    super.key,
    required this.child,
    this.title,
    this.padding = EdgeInsets.zero,
  });

  /// Optional title above the panel.
  final String? title;

  /// Content of the panel, usually rows split by hairlines.
  final Widget child;

  /// Space between the panel edge and [child].
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 16, bottom: 8),
              child: Semantics(
                header: true,
                child: Text(
                  title!,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: context.colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 20),
          GlassPanel(padding: padding, child: child),
        ],
      ),
    );
  }
}
