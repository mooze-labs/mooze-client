import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import '../consts.dart';

class PixQrCodeDisplay extends StatelessWidget {
  final BoxConstraints boxConstraints;
  final String pixQrData;

  const PixQrCodeDisplay({
    super.key,
    required this.pixQrData,
    required this.boxConstraints,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = boxConstraints.maxWidth - (contentPadding * 2);
    final screenHeight = boxConstraints.maxHeight;

    final reservedHeight = 400.0;
    final availableHeight = screenHeight - reservedHeight;
    final maxSize = math.min(screenWidth * 0.8, availableHeight * 0.8);
    final qrSize = math.max(180.0, math.min(maxSize, 314.0));

    return Center(
      child: Container(
        padding: const EdgeInsets.all(15),
        margin: EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: PrettyQrView.data(data: pixQrData),
      ),
    );
  }
}
