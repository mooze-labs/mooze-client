import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mooze_mobile/models/assets.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';

class PegAddressQrCode extends StatelessWidget {
  final String address;
  final bool pegIn;
  final double qrSize;

  const PegAddressQrCode({
    super.key,
    required this.address,
    required this.pegIn,
    required this.qrSize,
  });

  @override
  Widget build(BuildContext context) {
    final asset = pegIn ? AssetCatalog.bitcoin! : AssetCatalog.getById("lbtc")!;
    final paymentUri = pegIn ? "bitcoin:$address" : "liquidnetwork:$address";

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
            data: paymentUri,
            embeddedImage: AssetImage(asset.logoPath),
            embeddedImageStyle: QrEmbeddedImageStyle(size: Size(40, 40)),
            size: qrSize,
            backgroundColor: Colors.white,
          ),
        ),
        SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.transparent),
          ),
          child: GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: address));

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
                    address,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondary,
                      fontFamily: "roboto",
                      fontSize: 16,
                    ),
                    maxLines: 2,
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
