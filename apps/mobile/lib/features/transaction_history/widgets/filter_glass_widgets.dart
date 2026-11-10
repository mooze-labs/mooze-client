import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/press_scale.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Side margin of the content of a filter sheet.
const double kFilterSheetGutter = 20;

/// Frame of a history filter sheet: a floating [GlassSheet] in a
/// [DraggableScrollableSheet], with a grip, a title, the scrolling
/// [children], and the [actions] pinned at the bottom.
///
/// Put it in the builder of `showModalBottomSheet` with a transparent
/// background color.
class FilterSheetFrame extends StatelessWidget {
  const FilterSheetFrame({
    super.key,
    required this.title,
    required this.children,
    required this.actions,
    this.initialChildSize = 0.85,
    this.minChildSize = 0.7,
    this.maxChildSize = 0.95,
    this.snap = false,
    this.scrollable = true,
  });

  final String title;
  final List<Widget> children;
  final Widget actions;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  final bool snap;

  /// False lays [children] out in a column that fills the sheet, for
  /// content that sizes itself, such as a date wheel in an [Expanded].
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      expand: false,
      snap: snap,
      builder: (context, scrollController) {
        final header = Column(
          children: [
            const SizedBox(height: 10),
            const SheetGripHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                kFilterSheetGutter,
                16,
                kFilterSheetGutter,
                8,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: context.textTheme.titleMedium?.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );

        final Widget content;
        if (scrollable) {
          content = SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              kFilterSheetGutter,
              8,
              kFilterSheetGutter,
              8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          );
        } else {
          content = Padding(
            padding: const EdgeInsets.fromLTRB(
              kFilterSheetGutter,
              8,
              kFilterSheetGutter,
              0,
            ),
            child: Column(children: children),
          );
        }

        return GlassSheet(
          child: Column(
            children: [
              header,
              Expanded(child: content),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  kFilterSheetGutter,
                  8,
                  kFilterSheetGutter,
                  16 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: actions,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The small grip at the top of a glass sheet.
class SheetGripHandle extends StatelessWidget {
  const SheetGripHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: AppSurfaces.hairline(context),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// One section of a filter sheet: a muted title above its controls.
class FilterSection extends StatelessWidget {
  const FilterSection({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: context.textTheme.labelMedium?.copyWith(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// A neutral glass pill of a filter sheet.
///
/// An unselected pill is a hairline outline. The selected pill sits on a
/// glass lens and shows a check in the brand color. The pill is 40 pt
/// tall in a 48 pt touch target.
class FilterChipPill extends StatelessWidget {
  const FilterChipPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.expand = false,
    this.showCheck = true,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Fills the width given by the parent, for example in an [Expanded].
  final bool expand;

  /// Shows a check before the label of the selected pill.
  final bool showCheck;

  static const double _height = 40;
  static const double _target = 48;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final duration = Motion.of(context, Motion.durationFast);
    const shape = BorderRadius.all(Radius.circular(999));

    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: context.textTheme.labelLarge?.copyWith(
        color: selected ? colors.textPrimary : colors.textSecondary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showCheck)
          AnimatedSize(
            duration: duration,
            curve: Motion.curveMove,
            child: selected
                ? Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: colors.primaryColor,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        if (expand) Flexible(child: text) else text,
      ],
    );

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: _target,
          child: Center(
            widthFactor: expand ? null : 1,
            child: PressScale(
              child: SizedBox(
                height: _height,
                width: expand ? double.infinity : null,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: shape,
                          border: Border.all(
                            color: AppSurfaces.hairline(context),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: AnimatedOpacity(
                        opacity: selected ? 1 : 0,
                        duration: duration,
                        curve: Motion.curveMove,
                        child: const GlassLens(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Center(widthFactor: 1, child: content),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A row of pills that share the width equally.
class FilterChipRow extends StatelessWidget {
  const FilterChipRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

/// A glass input that opens a picker, such as a date range.
///
/// The field has the lens fill and a hairline. When [active], the hairline
/// turns into a glass lens rim and the [leadingIcon] takes the brand color.
class GlassPickerField extends StatelessWidget {
  const GlassPickerField({
    super.key,
    required this.text,
    required this.onTap,
    this.leadingIcon,
    this.trailingIcon = Icons.chevron_right_rounded,
    this.active = false,
    this.placeholder = false,
  });

  final String text;
  final VoidCallback onTap;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool active;

  /// Shows [text] as a muted hint, for a field with no value yet.
  final bool placeholder;

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(16));

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final glass = GlassStyle.of(context);
    final duration = Motion.of(context, Motion.durationFast);

    return Semantics(
      button: true,
      selected: active,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: _radius,
          child: AnimatedContainer(
            duration: duration,
            curve: Motion.curveMove,
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: glass.lensFill,
              borderRadius: _radius,
              border: Border.all(
                color: active
                    ? colors.primaryColor.withValues(alpha: 0.6)
                    : AppSurfaces.hairline(context),
              ),
            ),
            child: Row(
              children: [
                if (leadingIcon != null) ...[
                  Icon(
                    leadingIcon,
                    size: 18,
                    color: active ? colors.primaryColor : colors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: placeholder
                          ? colors.textSecondary
                          : colors.textPrimary,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 8),
                  Icon(trailingIcon, size: 20, color: colors.textTertiary),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A quiet text action of a filter sheet, such as "clear period".
class FilterTextAction extends StatelessWidget {
  const FilterTextAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.textSecondary;
    final style = TextButton.styleFrom(
      foregroundColor: color,
      minimumSize: const Size(48, 48),
      shape: const StadiumBorder(),
      textStyle: context.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
    final icon = this.icon;
    if (icon == null) {
      return TextButton(onPressed: onPressed, style: style, child: Text(label));
    }
    return TextButton.icon(
      onPressed: onPressed,
      style: style,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

/// The bottom actions of a filter sheet: a neutral pill that clears and the
/// brand pill that applies.
class FilterSheetActions extends StatelessWidget {
  const FilterSheetActions({
    super.key,
    required this.clearLabel,
    required this.onClear,
    required this.applyLabel,
    required this.onApply,
  });

  final String clearLabel;
  final VoidCallback onClear;
  final String applyLabel;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: NeutralPillButton(label: clearLabel, onPressed: onClear),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: BrandPillButton(label: applyLabel, onPressed: onApply),
        ),
      ],
    );
  }
}

/// The main action of a sheet: a brand pill.
class BrandPillButton extends StatelessWidget {
  const BrandPillButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          textStyle: context.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// A secondary action of a sheet: a neutral glass pill.
class NeutralPillButton extends StatelessWidget {
  const NeutralPillButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PressScale(
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: GlassStyle.of(context).lensFill,
          foregroundColor: colors.textPrimary,
          shape: StadiumBorder(
            side: BorderSide(color: AppSurfaces.hairline(context)),
          ),
          textStyle: context.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// The filter action of a history app bar: a round glass button, like the
/// back button. A brand dot marks active filters.
class HistoryFilterButton extends StatelessWidget {
  const HistoryFilterButton({
    super.key,
    required this.active,
    required this.onPressed,
    required this.tooltip,
  });

  final bool active;
  final VoidCallback onPressed;
  final String tooltip;

  /// Diameter of the glass circle, as the glass back button.
  static const double _size = 44;

  /// Space that [IconButton] keeps around its icon.
  static const double _buttonPadding = 8;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      selected: active,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: SizedBox.square(
          dimension: _size - 2 * _buttonPadding,
          child: OverflowBox(
            minWidth: _size,
            maxWidth: _size,
            minHeight: _size,
            maxHeight: _size,
            child: LiquidGlass(
              blurBackdrop: false,
              shadows: GlassStyle.of(context).controlShadows,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.tune_rounded, size: 20, color: colors.textPrimary),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: AnimatedScale(
                      scale: active ? 1 : 0,
                      duration: Motion.of(context, Motion.durationFast),
                      curve: Motion.curveMove,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colors.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A glass bar above a history list that names the active filters and
/// clears them.
class ActiveFiltersBar extends StatelessWidget {
  const ActiveFiltersBar({
    super.key,
    required this.text,
    required this.clearLabel,
    required this.onClear,
    this.icon = Icons.tune_rounded,
  });

  final String text;
  final String clearLabel;
  final VoidCallback onClear;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassPanel(
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colors.primaryColor),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  text,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: onClear,
              style: TextButton.styleFrom(
                foregroundColor: colors.textPrimary,
                minimumSize: const Size(48, 48),
                shape: const StadiumBorder(),
                textStyle: context.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(clearLabel),
            ),
          ],
        ),
      ),
    );
  }
}
