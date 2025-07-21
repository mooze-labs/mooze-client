import 'dart:math';
import 'package:flutter/material.dart';

class SimpleChartPainter extends CustomPainter {
  final bool isPositive;

  SimpleChartPainter({required this.isPositive});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = isPositive ? Colors.green : Colors.red
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true;

    final zeroLinePaint =
        Paint()
          ..color = Colors.grey.withValues(alpha: 0)
          ..strokeWidth = 1;

    final zeroY = size.height * 0.5;
    canvas.drawLine(Offset(0, zeroY), Offset(size.width, zeroY), zeroLinePaint);

    final path = Path();

    final dataValues =
        isPositive
            ? [-0.2, 0.8, 0.2, 0.8, 0.2, 1]
            : [-0, 1, -0.2, -0.1, -0.9, -0.1, -0.1];

    final points = <Offset>[];
    for (int i = 0; i < dataValues.length; i++) {
      final x = (i / (dataValues.length - 1)) * size.width;
      final y = size.height * (0.5 - (dataValues[i] * 0.4));
      points.add(Offset(x, y));
    }

    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];
        final midPoint = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
        path.quadraticBezierTo(p1.dx, p1.dy, midPoint.dx, midPoint.dy);
      }

      // Conecta ao último ponto
      path.lineTo(points.last.dx, points.last.dy);

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
