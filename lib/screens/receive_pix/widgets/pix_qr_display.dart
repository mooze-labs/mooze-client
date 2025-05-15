import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PixQrDisplay extends StatelessWidget {
  final String qrImageUrl;
  final String qrCopyPaste;

  const PixQrDisplay({
    super.key,
    required this.qrImageUrl,
    required this.qrCopyPaste,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.transparent),
          ),
          child: QrImageView(
            data: qrCopyPaste,
            size: 250.0,
            backgroundColor: Colors.white,
            eyeStyle: QrEyeStyle(
              color: Colors.black,
              eyeShape: QrEyeShape.circle,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Powered by Depix.info",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontFamily: "roboto",
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: qrCopyPaste));

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Endereço copiado!"),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: SelectableText(
                    qrCopyPaste,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondary,
                      fontFamily: "roboto",
                      fontSize: 16,
                    ),
                    maxLines: 3,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.copy, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
