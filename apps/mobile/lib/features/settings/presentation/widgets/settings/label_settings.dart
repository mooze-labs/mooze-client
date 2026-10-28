import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/action.dart';
import 'package:mooze_mobile/shared/widgets/app_icon.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/external_navigation.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/navigation_action.dart';
import 'package:mooze_mobile/features/settings/presentation/actions/toggle.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// One settings row inside a settings panel.
class LabelSettings extends StatefulWidget {
  /// Space between the panel edge and the row content.
  static const double horizontalPadding = 16;

  /// Size of the row icon.
  static const double iconSize = 20;

  /// Space between the icon and the text.
  static const double iconGap = 16;

  /// Distance from the panel edge to the row text. Dividers start here.
  static const double textInset = horizontalPadding + iconSize + iconGap;

  final String title;
  final String? iconPathSVG;
  final SettingsActions? action;
  final bool highlight;

  const LabelSettings({
    super.key,
    required this.title,
    this.iconPathSVG,
    this.action,
    this.highlight = false,
  });

  @override
  State<LabelSettings> createState() => _LabelSettingsState();
}

class _LabelSettingsState extends State<LabelSettings> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient:
            widget.highlight
                ? LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  // The gradient fades out, so the glass of the panel
                  // shows through at the start of the row.
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withValues(alpha: 0),
                  ],
                )
                : null,
        // The panel paints the surface. Only the highlighted row adds its
        // own gradient.
        color: null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.action != null ? () => widget.action!.execute() : null,
          child: Padding(
            padding: const EdgeInsets.only(
              top: 14,
              bottom: 14,
              left: LabelSettings.horizontalPadding,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    if (widget.iconPathSVG != null)
                      AppIcon(
                        path: widget.iconPathSVG!,
                        size: LabelSettings.iconSize,
                      ),
                    if (widget.iconPathSVG != null)
                      const SizedBox(width: LabelSettings.iconGap),
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                // A neutral chevron: the brand color stays on the highlighted
                // row and the main actions.
                if (widget.action is Navigation)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color:
                          widget.highlight
                              ? colorScheme.surfaceDim
                              : context.colors.textSecondary,
                    ),
                  ),
                if (widget.action is ExternalNavigation)
                  Padding(
                    padding: const EdgeInsets.only(
                      right: LabelSettings.horizontalPadding,
                    ),
                    child: AppIcon(
                      path: 'assets/icons/menu/settings/open_in_new.svg',
                    ),
                  ),
                if (widget.action is Toggle)
                  Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: SizedBox(
                      width: 48,
                      height: 27,
                      child: Switch.adaptive(
                        value: (widget.action as Toggle).value,
                        onChanged: (widget.action as Toggle).onChange,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
