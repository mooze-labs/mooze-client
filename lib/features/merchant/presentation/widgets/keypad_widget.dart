import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Keypad Widget (Presentation Layer)
///
/// A numeric keypad widget for entering monetary values in the merchant mode.
/// This widget provides a calculator-style interface with:
/// - Number buttons (0-9)
/// - Backspace button to delete last digit
/// - Add button to add the entered amount to the cart
///
/// The widget is responsive and adapts to different screen sizes,
/// adjusting font sizes, button sizes, and spacing accordingly.
///
/// Used in: Merchant Mode screen for quick product price entry
class KeypadWidget extends StatelessWidget {
  /// The current value being typed (displayed as R$ amount)
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final isVerySmallScreen = screenHeight < 650;
    final isSmallScreen = screenHeight < 700 && screenHeight >= 650;

    final isVeryNarrowScreen = screenWidth < 360;
    final isNarrowScreen = screenWidth < 380 && screenWidth >= 360;

    final topPadding =
        isVerySmallScreen || isVeryNarrowScreen
            ? 4.0
            : (isSmallScreen || isNarrowScreen ? 8.0 : 30.0);

    final titleFontSize =
        isVerySmallScreen || isVeryNarrowScreen
            ? 20.0
            : (isSmallScreen || isNarrowScreen ? 24.0 : 40.0);

    final verticalSpacing =
        isVerySmallScreen || isVeryNarrowScreen
            ? 4.0
            : (isSmallScreen || isNarrowScreen ? 6.0 : 20.0);

    final buttonFontSize =
        isVerySmallScreen || isVeryNarrowScreen
            ? 14.0
            : (isSmallScreen || isNarrowScreen ? 16.0 : 24.0);

    final buttonIconSize =
        isVerySmallScreen || isVeryNarrowScreen
            ? 14.0
            : (isSmallScreen || isNarrowScreen ? 16.0 : 24.0);

    final horizontalPadding =
        isVeryNarrowScreen
            ? 8.0
            : (isNarrowScreen
                ? 12.0
                : (isVerySmallScreen ? 16.0 : (isSmallScreen ? 30.0 : 40.0)));

    final buttonMargin =
        isVerySmallScreen || isVeryNarrowScreen
            ? 1.0
            : (isSmallScreen || isNarrowScreen ? 1.5 : 4.0);

    return Container(
      color: context.colors.backgroundColor,
      padding: EdgeInsets.only(top: topPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            key: valueInputKey,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Text(
              'R\$$typedValue',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: titleFontSize,
                fontWeight: FontWeight.w300,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: verticalSpacing),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final buttonSize =
                    (constraints.maxWidth - (buttonMargin * 6)) / 3;

                final aspectRatio =
                    isVerySmallScreen || isVeryNarrowScreen
                        ? 2.8
                        : (isSmallScreen || isNarrowScreen ? 1.8 : 1.2);

                final gridHeight =
                    (buttonSize / aspectRatio) * 4 + (buttonMargin * 8);

                return SizedBox(
                  height: gridHeight,
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: buttonMargin,
                    crossAxisSpacing: buttonMargin,
                    childAspectRatio: aspectRatio,
                    children: [
                      for (int i = 1; i <= 9; i++)
                        _buildKeypadButton(
                          context: context,
                          text: i.toString(),
                          onPressed: () => onAddDigit(i.toString()),
                          fontSize: buttonFontSize,
                          iconSize: buttonIconSize,
                          margin: buttonMargin,
                        ),
                      _buildKeypadButton(
                        context: context,
                        icon: Icons.backspace_outlined,
                        onPressed: onDeleteDigit,
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: buttonFontSize,
                        iconSize: buttonIconSize,
                        margin: buttonMargin,
                      ),
                      _buildKeypadButton(
                        context: context,
                        text: '0',
                        onPressed: () => onAddDigit('0'),
                        fontSize: buttonFontSize,
                        iconSize: buttonIconSize,
                        margin: buttonMargin,
                      ),
                      _buildKeypadButton(
                        context: context,
                        key: addButtonKey,
                        icon: Icons.add,
                        onPressed: onAddToTotal,
                        color: context.colors.positiveColor,
                        fontSize: buttonFontSize,
                        iconSize: buttonIconSize,
                        margin: buttonMargin,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton({
    required BuildContext context,
    Key? key,
    String? text,
    IconData? icon,
    required VoidCallback onPressed,
    Color? color,
    required double fontSize,
    required double iconSize,
    required double margin,
  }) {
    return Container(
      key: key,
      margin: EdgeInsets.all(margin / 2),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child:
            text != null
                ? Text(
                  text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: color ?? Theme.of(context).colorScheme.onSurface,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w300,
                  ),
                )
                : Icon(
                  icon,
                  color: color ?? Theme.of(context).colorScheme.onSurface,
                  size: iconSize,
                ),
      ),
    );
  }
}
