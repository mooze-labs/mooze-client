import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

void showErrorOverlay(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  double dragDistance = 0;

  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 20,
      right: 20,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          dragDistance += details.delta.dy;

          if (dragDistance.abs() > 40) {
            overlayEntry.remove();
          }
        },
        onVerticalDragEnd: (_) {
          dragDistance = 0;
        },
        child: Material(
          color: Colors.transparent,
          child: LiquidGlass(
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            opaque: true,
            blurBackdrop: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 20,
                    color: context.colors.negativeColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);

  Future.delayed(const Duration(seconds: 3), () {
    overlayEntry.remove();
  });
}
