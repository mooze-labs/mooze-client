import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
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

    return QrImageView(
      data: pixQrData,
      size: qrSize,
      backgroundColor: Colors.white,
    );
  }
}
