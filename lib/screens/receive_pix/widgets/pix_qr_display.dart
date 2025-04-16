import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

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
        Image.network(qrImageUrl, width: 250.0, height: 250.0),
        SizedBox(height: 10),
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
