import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mooze_mobile/shared/widgets/motion/press_scale.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The numeric keypad of the PIN screens.
///
/// It replaces the system keyboard, so the PIN screens look the same on
/// every device and the keys sit where the thumb is. The grid is 1–9, then
/// [leadingKey] (empty by default), 0, and backspace. A long press on
/// backspace clears the PIN.
///
/// The keys are the soft glass wells of the Merchant Mode keypad. A press
/// scales the key down and gives a selection click.
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    required this.onClear,
    this.leadingKey,
    this.enabled = true,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  /// Optional key at the bottom left, for example [PinKeypadKey.icon] for
  /// biometrics.
  final Widget? leadingKey;

  /// Turns every key off, for example while the PIN is checked.
  final bool enabled;

  /// Height of one key.
  static const double keyHeight = 60;

  /// Space between keys.
  static const double keyGap = 10;

  @override
  Widget build(BuildContext context) {
    PinKeypadKey digit(String value) => PinKeypadKey.digit(
      label: value,
      onPressed: enabled ? () => onDigit(value) : null,
    );

    final rows = <List<Widget>>[
      [digit('1'), digit('2'), digit('3')],
      [digit('4'), digit('5'), digit('6')],
      [digit('7'), digit('8'), digit('9')],
      [
        leadingKey ?? const SizedBox.shrink(),
        digit('0'),
        PinKeypadKey.icon(
          icon: Icons.backspace_outlined,
          semanticLabel: MaterialLocalizations.of(context).deleteButtonTooltip,
          onPressed: enabled ? onBackspace : null,
          onLongPress: enabled ? onClear : null,
        ),
      ],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < rows.length; row++) ...[
          if (row > 0) const SizedBox(height: keyGap),
          SizedBox(
            height: keyHeight,
            child: Row(
              children: [
                for (var col = 0; col < rows[row].length; col++) ...[
                  if (col > 0) const SizedBox(width: keyGap),
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

/// One key of the [PinKeypad].
///
/// A digit key is a soft glass well. An icon key has no well, so the
/// digits stay the main grid. A key without [onPressed] is dimmed.
class PinKeypadKey extends StatelessWidget {
  const PinKeypadKey.digit({
    super.key,
    required String this.label,
    this.onPressed,
  }) : icon = null,
       semanticLabel = null,
       onLongPress = null;

  const PinKeypadKey.icon({
    super.key,
    required IconData this.icon,
    required String this.semanticLabel,
    this.onPressed,
    this.onLongPress,
  }) : label = null;

  final String? label;
  final IconData? icon;
  final String? semanticLabel;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;

  /// Largest text scale of the digits. The digits are already large, so
  /// more would not fit in a key.
  static const double _maxDigitScale = 1.3;

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(18));

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final isDigit = label != null;
    final foreground = context.colors.textPrimary;

    final Widget face = isDigit
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
        : Icon(icon, size: 26, color: foreground);

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
                color: isDigit ? GlassStyle.of(context).lensFill : null,
                borderRadius: _radius,
                border: isDigit
                    ? Border.all(color: AppSurfaces.hairline(context))
                    : null,
              ),
              child: InkWell(
                borderRadius: _radius,
                onTap: enabled
                    ? () {
                        HapticFeedback.selectionClick();
                        onPressed!();
                      }
                    : null,
                onLongPress: onLongPress == null
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        onLongPress!();
                      },
                child: Center(child: face),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
