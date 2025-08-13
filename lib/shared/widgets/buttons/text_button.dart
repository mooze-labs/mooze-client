import 'package:flutter/material.dart';

class TransparentTextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final TextStyle? style;

  const TransparentTextButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: ButtonStyle(
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        padding: WidgetStateProperty.all(EdgeInsets.zero),
        minimumSize: WidgetStateProperty.all(Size.zero),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        text,
        style: style ?? Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}
