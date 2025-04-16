import 'dart:async';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mooze_mobile/models/network.dart';
import 'package:mooze_mobile/models/asset_catalog.dart';
import 'package:mooze_mobile/models/assets.dart';

class BIP21Uri {
  final String address;
  final double? amount;
  final String? assetId;
  final Network network;

  BIP21Uri({
    required this.address,
    this.amount,
    this.assetId,
    required this.network,
  });

  static BIP21Uri? parse(String uri) {
    try {
      // Check if it's a BIP21 URI
      if (!uri.startsWith('bitcoin:') && !uri.startsWith('liquidnetwork:')) {
        return null;
      }

      // Determine network
      final network =
          uri.startsWith('bitcoin:') ? Network.bitcoin : Network.liquid;

      // Remove scheme
      final withoutScheme = uri.substring(uri.indexOf(':') + 1);

      // Split address and parameters
      final parts = withoutScheme.split('?');
      final address = parts[0];

      // Parse parameters
      double? amount;
      String? assetId;

      if (parts.length > 1) {
        final params = parts[1].split('&');
        for (final param in params) {
          final keyValue = param.split('=');
          if (keyValue.length != 2) continue;

          final key = keyValue[0];
          final value = keyValue[1];

          if (key == 'amount') {
            amount = double.tryParse(value);
          } else if (key == 'asset_id' || key == 'assetid') {
            assetId = value;
          }
        }
      }

      return BIP21Uri(
        address: address,
        amount: amount,
        assetId: assetId,
        network: network,
      );
    } catch (e) {
      return null;
    }
  }
}

class AddressInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onAddressChanged;
  final Function(Asset) onAssetSelected;
  const AddressInput({
    super.key,
    required this.controller,
    required this.onAddressChanged,
    required this.onAssetSelected,
  });
  @override
  State<AddressInput> createState() => _AddressInputState();
}

class _AddressInputState extends State<AddressInput> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<bool> _hasCameraPermissionStatus() async {
    var permissionStatus = await Permission.camera.status;
    if (permissionStatus.isGranted) return true;
    if (permissionStatus.isPermanentlyDenied) return false;
    var requestResult = await Permission.camera.request();
    return requestResult.isGranted;
  }

  Future<void> _scanQrCode() async {
    bool hasCameraPermission = await _hasCameraPermissionStatus();
    if (!mounted) return;

    if (!hasCameraPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Ative as permissões para câmera nas configurações para ler códigos QR.",
          ),
          action: SnackBarAction(
            label: "Configurações",
            onPressed: openAppSettings,
          ),
        ),
      );
      return;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => QRScannerDialog(),
    );

    if (result != null && mounted) {
      // Try to parse as BIP21 URI
      final bip21Uri = BIP21Uri.parse(result);

      if (bip21Uri != null) {
        // If it's a BIP21 URI, use the address and select the appropriate asset
        setState(() {
          widget.controller.text = bip21Uri.address;
          widget.onAddressChanged(bip21Uri.address);

          // Select the appropriate asset based on the network and asset ID
          if (bip21Uri.network == Network.bitcoin) {
            widget.onAssetSelected(AssetCatalog.bitcoin!);
          } else if (bip21Uri.network == Network.liquid) {
            if (bip21Uri.assetId != null) {
              final asset = AssetCatalog.getByLiquidAssetId(bip21Uri.assetId!);
              if (asset != null) {
                widget.onAssetSelected(asset);
              }
            } else {
              // If no asset ID is specified, default to L-BTC
              widget.onAssetSelected(AssetCatalog.getById("lbtc")!);
            }
          }
        });
      } else {
        // If not a BIP21 URI, use the raw result
        setState(() {
          widget.controller.text = result;
          widget.onAddressChanged(result);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      maxLines: 1,
      textAlign: TextAlign.left,
      onChanged: (value) => widget.onAddressChanged(value),
      decoration: InputDecoration(
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        filled: Theme.of(context).inputDecorationTheme.filled,
        hintText: "Digite o endereço aqui",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            Icons.qr_code,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: _scanQrCode,
        ),
      ),
    );
  }
}

class QRScannerDialog extends StatefulWidget {
  const QRScannerDialog({super.key});

  @override
  State<QRScannerDialog> createState() => _QRScannerDialogState();
}

class _QRScannerDialogState extends State<QRScannerDialog> {
  final MobileScannerController controller = MobileScannerController();
  bool hasScanned = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Escanear QR Code'),
          leading: IconButton(
            icon: Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: MobileScanner(
          controller: controller,
          onDetect: (capture) {
            // Guard against multiple scans
            if (hasScanned) return;

            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                setState(() {
                  hasScanned = true;
                });
                Navigator.of(context).pop(barcode.rawValue);
                return;
              }
            }
          },
        ),
      ),
    );
  }
}
