import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:mooze_mobile/providers/fiat/fiat_provider.dart';
import 'package:mooze_mobile/widgets/inputs/convertible_amount_input.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:mooze_mobile/models/assets.dart';

class AddressInput extends StatefulWidget {
  final TextEditingController controller;
  const AddressInput({super.key, required this.controller});

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

  /*
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
    }

    try {
      String qrCodeResult = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666",
        "Cancelar",
        true,
        ScanMode.QR,
      );

      if (qrCodeResult != "-1" && mounted) {
        setState(() {
          widget.controller.text = qrCodeResult;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Houve um erro ao ler o QR code.")),
      );
    }
  }
  */

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      maxLines: 1,
      textAlign: TextAlign.left,
      decoration: InputDecoration(
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        filled: Theme.of(context).inputDecorationTheme.filled,
        hintText: "Digite o endereço aqui",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        /*
        suffixIcon: IconButton(
          icon: Icon(
            Icons.qr_code,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: _scanQrCode,
        ),
        */
      ),
    );
  }
}
