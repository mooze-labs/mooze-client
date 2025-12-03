import 'package:flutter/material.dart';

class KeypadWidget extends StatelessWidget {
  final String valorDigitado;
  final Function(String) onAdicionarNumero;
  final VoidCallback onApagarNumero;
  final VoidCallback onAdicionarAoTotal;
  final GlobalKey? valorInputKey;
  final GlobalKey? addButtonKey;

  const KeypadWidget({
    super.key,
    required this.valorDigitado,
    required this.onAdicionarNumero,
    required this.onApagarNumero,
    required this.onAdicionarAoTotal,
    this.valorInputKey,
    this.addButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    final isVerySmallScreen = screenHeight < 650;
    final isSmallScreen = screenHeight < 700 && screenHeight >= 650;

    final topPadding = isVerySmallScreen ? 8.0 : (isSmallScreen ? 12.0 : 30.0);
    final titleFontSize =
        isVerySmallScreen ? 28.0 : (isSmallScreen ? 32.0 : 40.0);
    final verticalSpacing =
        isVerySmallScreen ? 8.0 : (isSmallScreen ? 10.0 : 20.0);
    final buttonFontSize =
        isVerySmallScreen ? 18.0 : (isSmallScreen ? 20.0 : 24.0);
    final buttonIconSize =
        isVerySmallScreen ? 18.0 : (isSmallScreen ? 20.0 : 24.0);
    final horizontalPadding =
        isVerySmallScreen ? 20.0 : (isSmallScreen ? 30.0 : 40.0);
    final buttonMargin = isVerySmallScreen ? 2.0 : 4.0;

    return Container(
      color: Colors.black,
      padding: EdgeInsets.only(top: topPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Cabeçalho com valor
          Padding(
            key: valorInputKey,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Text(
              'R\$$valorDigitado',
              style: TextStyle(
                color: Colors.white,
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
                    isVerySmallScreen ? 0.9 : (isSmallScreen ? 1.0 : 1.2);
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
                          text: i.toString(),
                          onPressed: () => onAdicionarNumero(i.toString()),
                          fontSize: buttonFontSize,
                          iconSize: buttonIconSize,
                          margin: buttonMargin,
                        ),
                      _buildKeypadButton(
                        icon: Icons.backspace_outlined,
                        onPressed: onApagarNumero,
                        color: Colors.pink,
                        fontSize: buttonFontSize,
                        iconSize: buttonIconSize,
                        margin: buttonMargin,
                      ),
                      _buildKeypadButton(
                        text: '0',
                        onPressed: () => onAdicionarNumero('0'),
                        fontSize: buttonFontSize,
                        iconSize: buttonIconSize,
                        margin: buttonMargin,
                      ),
                      _buildKeypadButton(
                        key: addButtonKey,
                        icon: Icons.add,
                        onPressed: onAdicionarAoTotal,
                        color: Colors.green,
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
                  style: TextStyle(
                    color: color ?? Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w300,
                  ),
                )
                : Icon(icon, color: color ?? Colors.white, size: iconSize),
      ),
    );
  }
}
