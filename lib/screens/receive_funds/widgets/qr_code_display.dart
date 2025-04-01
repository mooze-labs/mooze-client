import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:mooze_mobile/models/assets.dart';

class QRCodeWidget extends StatelessWidget {
  final String data;
  final Asset asset;
  final double qrSize;

  const QRCodeWidget({
    Key? key,
    required this.data,
    required this.asset,
    required this.qrSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print(data);
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.transparent),
          ),
          child: QrImageView(
            data: data,
            embeddedImage: AssetImage(asset.logoPath),
            embeddedImageStyle: QrEmbeddedImageStyle(size: Size(40, 40)),
            size: qrSize,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "${asset.name}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}
