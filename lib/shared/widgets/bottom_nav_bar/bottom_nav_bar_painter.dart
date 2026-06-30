import 'package:flutter/material.dart';

/// Custom painter for the bottom navigation bar's shaped background.
///
/// [backgroundColor] is injected by the parent widget from the active theme
/// (via `context.colors.navBarBackground`) so the painter itself needs no
/// [BuildContext] and remains a pure [CustomPainter].
class BottomNavBarPainter extends CustomPainter {
  final Color backgroundColor;

  const BottomNavBarPainter({required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = backgroundColor
          ..style = PaintingStyle.fill;

    final path = Path();

    const double curveHeight = 25.0;
    final double centerX = size.width / 2;
    const double curveWidth = 150.0;
    const double cornerRadius = 15.0;

    path.moveTo(cornerRadius, size.height);
    path.lineTo(0, size.height);
    path.quadraticBezierTo(0, size.height, 0, 0);
    path.lineTo(0, curveHeight + cornerRadius + 2);
    path.quadraticBezierTo(0, curveHeight, cornerRadius, curveHeight);
    path.lineTo(centerX - curveWidth / 2, curveHeight);
    path.quadraticBezierTo(
      centerX - curveWidth / 3,
      curveHeight,
      centerX - 30,
      curveHeight - 18,
    );
    path.quadraticBezierTo(
      centerX,
      curveHeight - 45,
      centerX + 30,
      curveHeight - 18,
    );
    path.quadraticBezierTo(
      centerX + curveWidth / 3,
      curveHeight,
      centerX + curveWidth / 2,
      curveHeight,
    );
    path.lineTo(size.width - cornerRadius, curveHeight);
    path.quadraticBezierTo(
      size.width,
      curveHeight,
      size.width,
      curveHeight + cornerRadius,
    );
    path.lineTo(size.width, size.height - cornerRadius);
    path.quadraticBezierTo(size.width, size.height, size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(BottomNavBarPainter oldDelegate) =>
      oldDelegate.backgroundColor != backgroundColor;
}
