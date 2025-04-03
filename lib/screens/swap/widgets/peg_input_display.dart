import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class PegInputDisplay extends StatefulWidget {
  final bool pegIn;
  final TextEditingController addressController;
  final TextEditingController amountController;
  final bool receiveFromExternalWallet;
  final bool sendToExternalWallet;

  const PegInputDisplay({
    super.key,
    required this.pegIn,
    required this.amountController,
    required this.addressController,
    required this.receiveFromExternalWallet,
    required this.sendToExternalWallet,
  });

  @override
  State<PegInputDisplay> createState() => _PegInputDisplayState();
}

class _PegInputDisplayState extends State<PegInputDisplay> {
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
        widget.addressController.text = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.transparent),
            ),
            child: TextField(
              controller: widget.amountController,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "Digite o valor",
                hintStyle: TextStyle(
                  fontFamily: "roboto",
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: "roboto",
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: false,
              ),
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  if (newValue.text.isEmpty) {
                    return newValue;
                  }
                  // Allow only one decimal separator (either dot or comma)
                  final dotCount = newValue.text.split('.').length - 1;
                  final commaCount = newValue.text.split(',').length - 1;
                  if (dotCount + commaCount > 1) {
                    return oldValue;
                  }
                  return newValue;
                }),
              ],
            ),
          ),
          SizedBox(height: 16),
          if (widget.sendToExternalWallet)
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.transparent),
              ),
              child: TextField(
                controller: widget.addressController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText:
                      "Digite o endereço para enviar ${widget.pegIn ? "L-BTC" : "BTC"}",
                  hintStyle: TextStyle(
                    fontFamily: "roboto",
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.qr_code,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: _scanQrCode,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: "roboto",
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
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
