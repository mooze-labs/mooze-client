// lib/shared/widgets/keyboard_dismissible_widget.dart
import 'package:flutter/material.dart';

class KeyboardDismissibleWidget extends StatelessWidget {
  final Widget child;

  const KeyboardDismissibleWidget({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
          currentFocus.focusedChild?.unfocus();
        }
      },
      child: child,
    );
  }
}