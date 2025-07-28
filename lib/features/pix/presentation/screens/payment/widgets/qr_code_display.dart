import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../providers/pix_copypaste_provider.dart';

import '../consts.dart';

class PixQrCodeDisplay extends ConsumerWidget {
  final BoxConstraints boxConstraints;

  const PixQrCodeDisplay({super.key, required this.boxConstraints});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = boxConstraints.maxWidth - (contentPadding * 2);
    final screenHeight = boxConstraints.maxHeight;

    final reservedHeight = 400.0;
    final availableHeight = screenHeight - reservedHeight;
    final maxSize = math.min(screenWidth * 0.8, availableHeight * 0.8);
    final qrSize = math.max(180.0, math.min(maxSize, 314.0));
    final pixData = ref.read(pixCopypasteProvider);

    return QrImageView(
      data: pixData,
      size: qrSize,
      backgroundColor: Colors.white,
    );
  }
}
