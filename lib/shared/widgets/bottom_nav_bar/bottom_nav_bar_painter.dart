import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

class BottomNavBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint =
        Paint()
          ..color = AppColors.navBarBackground
          ..style = PaintingStyle.fill;

    Path path = Path();

    double curveHeight = 25.0;
    double centerX = size.width / 2;
    double curveWidth = 150.0;
    double cornerRadius = 15.0;

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
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
