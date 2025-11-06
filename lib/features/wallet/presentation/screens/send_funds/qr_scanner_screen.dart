import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import '../../providers/send_funds/address_provider.dart';
import '../../providers/send_funds/address_controller_provider.dart';
import '../../providers/send_funds/network_detection_provider.dart';
import '../../providers/send_funds/selected_asset_provider.dart';

class QRCodeScannerScreen extends ConsumerStatefulWidget {
  const QRCodeScannerScreen({super.key});

  @override
  ConsumerState<QRCodeScannerScreen> createState() =>
      _QRCodeScannerScreenState();
}

class _QRCodeScannerScreenState extends ConsumerState<QRCodeScannerScreen>
    with TickerProviderStateMixin {
  MobileScannerController cameraController = MobileScannerController();
  bool isFlashOn = false;
  bool isScanning = true;
  late AnimationController _animationController;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() {
          isScanning = false;
        });

        HapticFeedback.mediumImpact();

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

    _autoSwitchAssetBasedOnNetwork(address);

    context.pop();
  }

  void _autoSwitchAssetBasedOnNetwork(String address) {
    if (address.isEmpty) return;

    final networkType = NetworkDetectionService.detectNetworkType(address);
    final currentAsset = ref.read(selectedAssetProvider);

    if (currentAsset != Asset.btc && currentAsset != Asset.lbtc) {
      return;
    }

    Asset? newAsset;

    switch (networkType) {
      case NetworkType.bitcoin:
        if (currentAsset != Asset.btc) {
          newAsset = Asset.btc;
        }
        break;
      case NetworkType.lightning:
      case NetworkType.liquid:
        if (currentAsset != Asset.lbtc) {
          newAsset = Asset.lbtc;
        }
        break;
      case NetworkType.unknown:
        break;
    }

    if (newAsset != null) {
      ref.read(selectedAssetProvider.notifier).state = newAsset;
    }
  }

  void _toggleFlash() {
    setState(() {
      isFlashOn = !isFlashOn;
    });
    cameraController.toggleTorch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Escanear QR Code'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(controller: cameraController, onDetect: _onDetect),
          _buildModernOverlay(),
          _buildInstructions(),
          _buildControlButtons(),
        ],
      ),
    );
  }

  Widget _buildModernOverlay() {
    return Container(
      decoration: ShapeDecoration(
        shape: ModernQrScannerOverlayShape(
          borderColor: Theme.of(context).colorScheme.primary,
          borderRadius: 20,
          borderLength: 40,
          borderWidth: 4,
          cutOutSize: 280,
          overlayColor: Colors.black.withValues(alpha: 0.7),
        ),
      ),
      child: AnimatedBuilder(
        animation: _scanLineAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: ScanLinePainter(
              progress: _scanLineAnimation.value,
              color: Theme.of(context).colorScheme.primary,
              isScanning: isScanning,
            ),
            child: Container(),
          );
        },
      ),
    );
  }

  Widget _buildInstructions() {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isScanning
                        ? 'Procurando QR Code...'
                        : 'QR Code encontrado!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Posicione o QR code dentro da área destacada',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Bitcoin • Lightning • Liquid',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
                fontWeight: FontWeight.w300,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: _buildControlButton(
                icon: isFlashOn ? Icons.flash_on : Icons.flash_off,
                label: 'Flash',
                isActive: isFlashOn,
                onTap: _toggleFlash,
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: _buildControlButton(
                icon: Icons.flip_camera_ios,
                label: 'Câmera',
                isActive: false,
                onTap: () => cameraController.switchCamera(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color:
              isActive
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isActive
                    ? Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color:
                  isActive
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color:
                    isActive
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScanLinePainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isScanning;

  ScanLinePainter({
    required this.progress,
    required this.color,
    required this.isScanning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isScanning) return;

    final paint =
        Paint()
          ..color = color.withValues(alpha: 0.8)
          ..strokeWidth = 3
          ..shader = LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color,
              color.withValues(alpha: 0.1),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, 3));

    final cutOutSize = 280.0;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scanAreaTop = centerY - cutOutSize / 2;
    final scanAreaBottom = centerY + cutOutSize / 2;
    final scanAreaLeft = centerX - cutOutSize / 2;
    final scanAreaRight = centerX + cutOutSize / 2;

    final currentY = scanAreaTop + (scanAreaBottom - scanAreaTop) * progress;

    canvas.drawLine(
      Offset(scanAreaLeft + 20, currentY),
      Offset(scanAreaRight - 20, currentY),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ModernQrScannerOverlayShape extends ShapeBorder {
  const ModernQrScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 4.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 20,
    this.borderLength = 40,
    double? cutOutSize,
  }) : cutOutSize = cutOutSize ?? 280;

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
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final mBorderLength = borderLength;
    final mCutOutSize = cutOutSize < width ? cutOutSize : width - borderOffset;

    final backgroundPaint =
        Paint()
          ..color = overlayColor
          ..style = PaintingStyle.fill;

    final borderPaint =
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth
          ..strokeCap = StrokeCap.round;

    final glowPaint =
        Paint()
          ..color = borderColor.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth * 2
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final cutOutRect = Rect.fromLTWH(
      rect.left + (width - mCutOutSize) / 2 + borderOffset,
      rect.top + (height - mCutOutSize) / 2 + borderOffset,
      mCutOutSize - borderOffset * 2,
      mCutOutSize - borderOffset * 2,
    );

    // Draw background overlay
    canvas.drawPath(getOuterPath(rect), backgroundPaint);

    // Draw corner borders with glow
    _drawCornerBorders(canvas, cutOutRect, glowPaint, mBorderLength);
    _drawCornerBorders(canvas, cutOutRect, borderPaint, mBorderLength);
  }

  void _drawCornerBorders(
    Canvas canvas,
    Rect cutOutRect,
    Paint paint,
    double borderLength,
  ) {
    // Top-left corner
    canvas.drawLine(
      Offset(
        cutOutRect.left - borderWidth / 2,
        cutOutRect.top - borderWidth / 2,
      ),
      Offset(
        cutOutRect.left - borderWidth / 2 + borderLength,
        cutOutRect.top - borderWidth / 2,
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        cutOutRect.left - borderWidth / 2,
        cutOutRect.top - borderWidth / 2,
      ),
      Offset(
        cutOutRect.left - borderWidth / 2,
        cutOutRect.top - borderWidth / 2 + borderLength,
      ),
      paint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(
        cutOutRect.right + borderWidth / 2,
        cutOutRect.top - borderWidth / 2,
      ),
      Offset(
        cutOutRect.right + borderWidth / 2 - borderLength,
        cutOutRect.top - borderWidth / 2,
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        cutOutRect.right + borderWidth / 2,
        cutOutRect.top - borderWidth / 2,
      ),
      Offset(
        cutOutRect.right + borderWidth / 2,
        cutOutRect.top - borderWidth / 2 + borderLength,
      ),
      paint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(
        cutOutRect.left - borderWidth / 2,
        cutOutRect.bottom + borderWidth / 2,
      ),
      Offset(
        cutOutRect.left - borderWidth / 2 + borderLength,
        cutOutRect.bottom + borderWidth / 2,
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        cutOutRect.left - borderWidth / 2,
        cutOutRect.bottom + borderWidth / 2,
      ),
      Offset(
        cutOutRect.left - borderWidth / 2,
        cutOutRect.bottom + borderWidth / 2 - borderLength,
      ),
      paint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(
        cutOutRect.right + borderWidth / 2,
        cutOutRect.bottom + borderWidth / 2,
      ),
      Offset(
        cutOutRect.right + borderWidth / 2 - borderLength,
        cutOutRect.bottom + borderWidth / 2,
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        cutOutRect.right + borderWidth / 2,
        cutOutRect.bottom + borderWidth / 2,
      ),
      Offset(
        cutOutRect.right + borderWidth / 2,
        cutOutRect.bottom + borderWidth / 2 - borderLength,
      ),
      paint,
    );
  }

  @override
  ShapeBorder scale(double t) => ModernQrScannerOverlayShape(
    borderColor: borderColor,
    borderWidth: borderWidth,
    overlayColor: overlayColor,
    borderRadius: borderRadius,
    borderLength: borderLength,
    cutOutSize: cutOutSize,
  );
}
