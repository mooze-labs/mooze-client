import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../providers/send_funds/address_provider.dart';
import '../../providers/send_funds/address_controller_provider.dart';

class QRCodeScannerScreen extends ConsumerStatefulWidget {
  const QRCodeScannerScreen({super.key});

  @override
  ConsumerState<QRCodeScannerScreen> createState() =>
      _QRCodeScannerScreenState();
}

class _QRCodeScannerScreenState extends ConsumerState<QRCodeScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final scannedValue = barcode.rawValue!;
        _processScannedData(scannedValue);
        break;
      }
    }
  }

  void _processScannedData(String data) {
    String address = data;

    if (data.startsWith('bitcoin:')) {
      final uri = Uri.parse(data);
      address = uri.path;
    } else if (data.startsWith('lightning:')) {
      address = data.replaceFirst('lightning:', '');
    } else if (data.startsWith('liquidnetwork:')) {
      address = data.replaceFirst('liquidnetwork:', '');
    }

    ref.read(addressStateProvider.notifier).state = address;
    ref.read(addressControllerProvider).text = address;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR Code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            onPressed: () => cameraController.toggleTorch(),
            icon: const Icon(Icons.flash_off, color: Colors.grey),
          ),
          IconButton(
            onPressed: () => cameraController.switchCamera(),
            icon: const Icon(Icons.camera_rear),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: cameraController, onDetect: _onDetect),
          _buildOverlay(),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return Container(
      decoration: ShapeDecoration(
        shape: QrScannerOverlayShape(
          borderColor: Theme.of(context).colorScheme.primary,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: 250,
        ),
      ),
      child: const Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Posicione o QR code dentro do quadrado',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class QrScannerOverlayShape extends ShapeBorder {
  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    double? cutOutSize,
  }) : cutOutSize = cutOutSize ?? 250;

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path outerPath = Path()..addRect(rect);
    Path cutOutPath =
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: rect.center,
              width: cutOutSize,
              height: cutOutSize,
            ),
            Radius.circular(borderRadius),
          ),
        );
    return Path.combine(PathOperation.difference, outerPath, cutOutPath);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final mBorderLength =
        borderLength > cutOutSize / 2 + borderOffset
            ? borderWidthSize / 2
            : borderLength;
    final mCutOutSize = cutOutSize < width ? cutOutSize : width - borderOffset;

    final backgroundPaint =
        Paint()
          ..color = overlayColor
          ..style = PaintingStyle.fill;

    final borderPaint =
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;

    final cutOutRect = Rect.fromLTWH(
      rect.left + (width - mCutOutSize) / 2 + borderOffset,
      rect.top + (height - mCutOutSize) / 2 + borderOffset,
      mCutOutSize - borderOffset * 2,
      mCutOutSize - borderOffset * 2,
    );

    canvas.drawPath(getOuterPath(rect), backgroundPaint);

    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        cutOutRect.left - borderOffset,
        cutOutRect.top - borderOffset,
        cutOutRect.left + mBorderLength,
        cutOutRect.top + borderWidth * 2,
        topLeft: Radius.circular(borderRadius),
      ),
      borderPaint,
    );

    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        cutOutRect.left - borderOffset,
        cutOutRect.top - borderOffset,
        cutOutRect.left + borderWidth * 2,
        cutOutRect.top + mBorderLength,
        topLeft: Radius.circular(borderRadius),
      ),
      borderPaint,
    );

    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        cutOutRect.right - mBorderLength,
        cutOutRect.top - borderOffset,
        cutOutRect.right + borderOffset,
        cutOutRect.top + borderWidth * 2,
        topRight: Radius.circular(borderRadius),
      ),
      borderPaint,
    );

    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        cutOutRect.right - borderWidth * 2,
        cutOutRect.top - borderOffset,
        cutOutRect.right + borderOffset,
        cutOutRect.top + mBorderLength,
        topRight: Radius.circular(borderRadius),
      ),
      borderPaint,
    );

    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        cutOutRect.left - borderOffset,
        cutOutRect.bottom - borderWidth * 2,
        cutOutRect.left + mBorderLength,
        cutOutRect.bottom + borderOffset,
        bottomLeft: Radius.circular(borderRadius),
      ),
      borderPaint,
    );

    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        cutOutRect.left - borderOffset,
        cutOutRect.bottom - mBorderLength,
        cutOutRect.left + borderWidth * 2,
        cutOutRect.bottom + borderOffset,
        bottomLeft: Radius.circular(borderRadius),
      ),
      borderPaint,
    );

    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        cutOutRect.right - mBorderLength,
        cutOutRect.bottom - borderWidth * 2,
        cutOutRect.right + borderOffset,
        cutOutRect.bottom + borderOffset,
        bottomRight: Radius.circular(borderRadius),
      ),
      borderPaint,
    );

    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        cutOutRect.right - borderWidth * 2,
        cutOutRect.bottom - mBorderLength,
        cutOutRect.right + borderOffset,
        cutOutRect.bottom + borderOffset,
        bottomRight: Radius.circular(borderRadius),
      ),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) => QrScannerOverlayShape(
    borderColor: borderColor,
    borderWidth: borderWidth,
    overlayColor: overlayColor,
  );
}
