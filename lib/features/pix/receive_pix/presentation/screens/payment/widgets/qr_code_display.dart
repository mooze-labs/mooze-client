import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

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
