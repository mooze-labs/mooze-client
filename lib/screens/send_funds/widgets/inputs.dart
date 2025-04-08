import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class AddressInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onAddressChanged;
  const AddressInput({
    super.key,
    required this.controller,
    required this.onAddressChanged,
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
      setState(() {
        widget.controller.text = result;
        widget.onAddressChanged(result);
      });
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
