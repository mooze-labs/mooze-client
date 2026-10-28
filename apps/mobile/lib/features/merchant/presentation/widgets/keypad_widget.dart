import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/merchant_flow_scaffold.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_formatters.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/motion/press_scale.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Keypad Widget (Presentation Layer)
///
/// The numeric keypad of Merchant Mode. The merchant types a loose value
/// and adds it to the sale.
///
/// The typed value sits at the top, as an input with a thin rule below it.
/// The keys fill the space below: 1–9, backspace, 0, and the green add key.
/// Each key grows with the free height up to [maxKeyHeight] and keeps at
/// least [minKeyHeight]. On a short screen, or with very large text, the
/// keypad scrolls instead of overflowing.
///
/// Used in: Merchant Mode screen for quick product price entry
class KeypadWidget extends StatelessWidget {
  /// The current value being typed, such as `20.00`.
  final String typedValue;

  /// Callback when a number button is pressed
  /// Parameter: the digit pressed ('0'-'9')
  final Function(String) onAddDigit;

  /// Callback when backspace button is pressed
  final VoidCallback onDeleteDigit;

  /// Callback when 'Add to Total' button is pressed
  final VoidCallback onAddToTotal;

  /// Global key for the value display (used for tutorials)
  final GlobalKey? valueInputKey;

  /// Global key for the add button (used for tutorials)
  final GlobalKey? addButtonKey;

  const KeypadWidget({
    super.key,
    required this.typedValue,
    required this.onAddDigit,
    required this.onDeleteDigit,
    required this.onAddToTotal,
    this.valueInputKey,
    this.addButtonKey,
  });

  /// Smallest key height. It is also the smallest touch target.
  static const double minKeyHeight = 48;

  /// Largest key height.
  static const double maxKeyHeight = 64;

  /// Space between keys.
  static const double keyGap = 10;

  /// Side margin of the keypad.
  static const double gutter = 20;

  @override
  Widget build(BuildContext context) {
    final cents = merchantCents(double.tryParse(typedValue) ?? 0);
    final display = Padding(
      key: valueInputKey,
      padding: const EdgeInsets.symmetric(horizontal: gutter),
      child: _TypedValue(amountInCents: cents),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // The display takes about one line of large digits and its rule.
        // The keys share the rest.
        final displayHeight = MediaQuery.textScalerOf(context).scale(40) + 25;
        final free = constraints.maxHeight - displayHeight - 8 - keyGap * 3;
        final keyHeight = free / 4;
        final keys = Padding(
          padding: const EdgeInsets.symmetric(horizontal: gutter),
          child: _KeyGrid(
            keyHeight: keyHeight.clamp(minKeyHeight, maxKeyHeight),
            canAdd: cents > 0,
            onAddDigit: onAddDigit,
            onDeleteDigit: onDeleteDigit,
            onAddToTotal: onAddToTotal,
            addButtonKey: addButtonKey,
          ),
        );

        if (keyHeight < minKeyHeight) {
          return SingleChildScrollView(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Column(
              children: [display, const SizedBox(height: 16), keys],
            ),
          );
        }
        // The value stays in the middle of the free space. The keys stay
        // at the bottom, near the thumb and the main button.
        return Column(
          children: [
            Expanded(
              child: Center(
                child: FittedBox(fit: BoxFit.scaleDown, child: display),
              ),
            ),
            keys,
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

/// The typed value: a muted currency symbol, the digits, and a rule.
///
/// Screen readers announce the new value after each key.
class _TypedValue extends StatelessWidget {
  const _TypedValue({required this.amountInCents});

  final int amountInCents;

  @override
  Widget build(BuildContext context) {
    const tabular = [FontFeature.tabularFigures()];
    final isEmpty = amountInCents == 0;
    return Semantics(
      liveRegion: true,
      label: formatBrlCents(amountInCents),
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  r'R$',
                  style: context.textTheme.titleLarge?.copyWith(
                    color: context.colors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontFeatures: tabular,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  merchantBrlDigits(amountInCents),
                  style: context.textTheme.headlineLarge?.copyWith(
                    // An empty value reads as a placeholder.
                    color: isEmpty
                        ? context.colors.textTertiary
                        : context.colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.6,
                    fontFeatures: tabular,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 160,
            child: Divider(
              height: 1,
              thickness: 1,
              color: AppSurfaces.hairline(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// The 4 × 3 key grid.
class _KeyGrid extends StatelessWidget {
  const _KeyGrid({
    required this.keyHeight,
    required this.canAdd,
    required this.onAddDigit,
    required this.onDeleteDigit,
    required this.onAddToTotal,
    this.addButtonKey,
  });

  final double keyHeight;
  final bool canAdd;
  final Function(String) onAddDigit;
  final VoidCallback onDeleteDigit;
  final VoidCallback onAddToTotal;
  final GlobalKey? addButtonKey;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    Widget digit(String value) =>
        _KeypadKey.digit(label: value, onPressed: () => onAddDigit(value));

    final rows = [
      [digit('1'), digit('2'), digit('3')],
      [digit('4'), digit('5'), digit('6')],
      [digit('7'), digit('8'), digit('9')],
      [
        _KeypadKey.icon(
          icon: Icons.backspace_outlined,
          semanticLabel: MaterialLocalizations.of(context).deleteButtonTooltip,
          onPressed: onDeleteDigit,
        ),
        digit('0'),
        _KeypadKey.add(
          key: addButtonKey,
          semanticLabel: t.merchant_step_add_value_title,
          onPressed: canAdd ? onAddToTotal : null,
        ),
      ],
    ];

    return Column(
      children: [
        for (var row = 0; row < rows.length; row++) ...[
          if (row > 0) const SizedBox(height: KeypadWidget.keyGap),
          SizedBox(
            height: keyHeight,
            child: Row(
              children: [
                for (var col = 0; col < rows[row].length; col++) ...[
                  if (col > 0) const SizedBox(width: KeypadWidget.keyGap),
                  Expanded(child: rows[row][col]),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

enum _KeyKind { digit, icon, add }

/// One key of the keypad.
///
/// A digit key is a soft glass well. The backspace key has no well, so the
/// digits stay the main grid. The add key is a green well with a plus, in
/// the tertiary container colors: it is the only key that changes the
/// sale. It is dimmed and inactive while
/// the typed value is zero.
///
/// A press scales the key down and gives a selection click.
class _KeypadKey extends StatelessWidget {
  const _KeypadKey.digit({required String this.label, required this.onPressed})
    : kind = _KeyKind.digit,
      icon = null,
      semanticLabel = null;

  const _KeypadKey.icon({
    required IconData this.icon,
    required String this.semanticLabel,
    required this.onPressed,
  }) : kind = _KeyKind.icon,
       label = null;

  const _KeypadKey.add({
    super.key,
    required String this.semanticLabel,
    required this.onPressed,
  }) : kind = _KeyKind.add,
       icon = Icons.add_rounded,
       label = null;

  final _KeyKind kind;
  final String? label;
  final IconData? icon;
  final String? semanticLabel;
  final VoidCallback? onPressed;

  /// Largest text scale of the digits. The digits are already large, so
  /// more would not fit in a key.
  static const double _maxDigitScale = 1.3;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(18));
    final enabled = onPressed != null;
    final colorScheme = context.colorScheme;

    final (Color? fill, Color? border, Color foreground) = switch (kind) {
      _KeyKind.digit => (
        GlassStyle.of(context).lensFill,
        AppSurfaces.hairline(context),
        context.colors.textPrimary,
      ),
      _KeyKind.icon => (null, null, context.colors.textPrimary),
      // The green container pair keeps the plus above 9:1 in both themes.
      _KeyKind.add => (
        colorScheme.tertiaryContainer,
        colorScheme.tertiary.withValues(alpha: 0.4),
        colorScheme.onTertiaryContainer,
      ),
    };

    final Widget face = label != null
        ? Text(
            label!,
            textScaler: MediaQuery.textScalerOf(
              context,
            ).clamp(maxScaleFactor: _maxDigitScale),
            style: context.textTheme.headlineSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          )
        : Icon(icon, size: kind == _KeyKind.add ? 28 : 24, color: foreground);

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: PressScale(
          child: Material(
            type: MaterialType.transparency,
            child: Ink(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: radius,
                border: border == null ? null : Border.all(color: border),
              ),
              child: InkWell(
                borderRadius: radius,
                onTap: enabled
                    ? () {
                        HapticFeedback.selectionClick();
                        onPressed!();
                      }
                    : null,
                child: Center(child: face),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
