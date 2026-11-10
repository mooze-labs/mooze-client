import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// A round glass button that scrolls a legal document back to the top.
///
/// It floats over moving text, so the glass blurs what is behind it.
class LegalDocumentBackToTopButton extends StatelessWidget {
  final VoidCallback onPressed;

  const LegalDocumentBackToTopButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: LiquidGlass(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox.square(
              dimension: 48,
              child: Icon(
                Icons.keyboard_arrow_up_rounded,
                size: 26,
                color: context.colors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
