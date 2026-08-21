import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import '../../providers/send_funds/address_provider.dart';
import '../../providers/send_funds/address_controller_provider.dart';
import '../../providers/send_funds/network_detection_provider.dart';
import '../../providers/send_funds/selected_asset_provider.dart';
import '../../providers/send_funds/qr_validation_service.dart';
import '../../providers/send_funds/amount_detection_provider.dart';
import 'package:mooze_mobile/shared/widgets.dart';

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
    final validationResult = QrValidationService.validateQrData(data);

    if (!validationResult.isValid) {
      setState(() {
        isScanning = false;
      });

      AppSnackBar.error(context, validationResult.localize(context));

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            isScanning = true;
          });
        }
      });

      return;
    }

    String cleanedData = validationResult.cleanedData ?? data;

    ref.read(addressStateProvider.notifier).state = cleanedData;

    String displayAddress = cleanedData;

    if (cleanedData.startsWith('bitcoin:') ||
        cleanedData.startsWith('liquidnetwork:') ||
        cleanedData.startsWith('liquid:')) {
      try {
        final uri = Uri.parse(cleanedData);
        displayAddress = uri.path;
      } catch (e) {
        displayAddress = cleanedData;
      }
    }

    ref.read(addressControllerProvider).text = displayAddress;

    _autoSwitchAssetBasedOnNetwork(cleanedData);

    context.pop();
  }

  void _autoSwitchAssetBasedOnNetwork(String address) {
    if (address.isEmpty) return;

    final detectedResult = AmountDetectionService.detectAmount(address);

    if (detectedResult.asset != null) {
      ref.read(selectedAssetProvider.notifier).state = detectedResult.asset!;
      return;
    }

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

  double _computeCutOutSize(BoxConstraints constraints) {
    final minSide =
        constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
    return (minSide * 0.72).clamp(200.0, 340.0);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return PlatformSafeArea(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: context.colors.backgroundColor,
        appBar: AppBar(
          title: Text(t.wallet_send_address_scan_qr),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: context.colors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: context.colors.textPrimary),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: context.colors.textPrimary,
            onPressed: () => context.pop(),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;
            return isLandscape
                ? _buildLandscapeLayout(context, constraints)
                : _buildPortraitLayout(context, constraints);
          },
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final mediaPadding = MediaQuery.of(context).padding;
    final bottomReserve = 240.0 + mediaPadding.bottom;
    const topReserve = kToolbarHeight;
    final availableForCutout = (constraints.maxHeight -
            topReserve -
            bottomReserve)
        .clamp(200.0, double.infinity);
    final cutOutSize = _computeCutOutSize(
      BoxConstraints(
        maxWidth: constraints.maxWidth,
        maxHeight: availableForCutout,
      ),
    );
    final cutOutVerticalOffset = (topReserve - bottomReserve) / 2;

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildScannerStack(cutOutSize, cutOutVerticalOffset),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildFloatingBottomControls(context),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final mediaPadding = MediaQuery.of(context).padding;
    final sidePanelWidth = 320.0;
    final cameraAreaWidth = (constraints.maxWidth -
            sidePanelWidth -
            mediaPadding.right)
        .clamp(240.0, double.infinity);
    final availableHeight = (constraints.maxHeight - kToolbarHeight).clamp(
      180.0,
      double.infinity,
    );
    final cutOutSize = _computeCutOutSize(
      BoxConstraints(maxWidth: cameraAreaWidth, maxHeight: availableHeight),
    );
    final cutOutVerticalOffset = kToolbarHeight / 2;

    return Row(
      children: [
        Expanded(child: _buildScannerStack(cutOutSize, cutOutVerticalOffset)),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: sidePanelWidth),
          child: _buildBottomPanel(context),
        ),
      ],
    );
  }

  Widget _buildScannerStack(double cutOutSize, double cutOutVerticalOffset) {
    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: cameraController,
          onDetect: _onDetect,
          fit: BoxFit.cover,
          placeholderBuilder: _buildScannerPlaceholder,
          errorBuilder: _buildScannerError,
        ),
        _buildModernOverlay(cutOutSize, cutOutVerticalOffset),
      ],
    );
  }

  Widget _buildFloatingBottomControls(BuildContext context) {
    return Container(
      decoration: BoxDecoration(),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusChip(context),
              const SizedBox(height: 12),
              _buildInstructionText(context),
              const SizedBox(height: 16),
              _buildControlButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScannerPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      color: context.colors.backgroundColor,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).qr_scanner_searching,
            style: TextStyle(
              color: context.colors.backgroundColor.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerError(
    BuildContext context,
    MobileScannerException error,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      color: context.colors.backgroundColor,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.no_photography_outlined,
            size: 48,
            color: colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            error.errorDetails?.message ??
                AppLocalizations.of(context).qr_scanner_position_hint,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModernOverlay(double cutOutSize, double cutOutVerticalOffset) {
    final colorScheme = Theme.of(context).colorScheme;
    final overlayColor = context.colors.backgroundColor.withValues(alpha: 0.6);
    return Container(
      decoration: ShapeDecoration(
        shape: ModernQrScannerOverlayShape(
          borderColor: colorScheme.primary,
          borderRadius: 20,
          borderLength: 36,
          borderWidth: 4,
          cutOutSize: cutOutSize,
          cutOutVerticalOffset: cutOutVerticalOffset,
          overlayColor: overlayColor,
        ),
      ),
      child: AnimatedBuilder(
        animation: _scanLineAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: ScanLinePainter(
              progress: _scanLineAnimation.value,
              color: colorScheme.primary,
              isScanning: isScanning,
              cutOutSize: cutOutSize,
              cutOutVerticalOffset: cutOutVerticalOffset,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context) {
    return Material(
      color: context.colors.backgroundColor,
      elevation: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusChip(context),
              const SizedBox(height: 12),
              _buildInstructionText(context),
              const SizedBox(height: 16),
              _buildControlButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_scanner, color: colorScheme.primary, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              isScanning ? t.qr_scanner_searching : t.qr_scanner_found,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionText(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          t.qr_scanner_position_hint,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          t.qr_scanner_supported_networks,
          style: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.65),
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildControlButtons(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _buildControlButton(
            icon: isFlashOn ? Icons.flash_on : Icons.flash_off,
            label: t.qr_scanner_flash_label,
            isActive: isFlashOn,
            onTap: _toggleFlash,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildControlButton(
            icon: Icons.flip_camera_ios,
            label: t.qr_scanner_camera_label,
            isActive: false,
            onTap: () => cameraController.switchCamera(),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = colorScheme.primary;
    final inactiveBg = colorScheme.onSurface.withValues(alpha: 0.05);
    final inactiveFg = colorScheme.onSurface;
    final borderRadius = BorderRadius.circular(12);

    return Material(
      color: isActive ? activeColor.withValues(alpha: 0.4) : inactiveBg,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.05),
            borderRadius: borderRadius,
            border: Border.all(
              color:
                  isActive
                      ? activeColor.withValues(alpha: 0.5)
                      : colorScheme.onSurface.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? activeColor : inactiveFg,
                size: 22,
                semanticLabel: label,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? activeColor : inactiveFg,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScanLinePainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isScanning;
  final double cutOutSize;
  final double cutOutVerticalOffset;

  ScanLinePainter({
    required this.progress,
    required this.color,
    required this.isScanning,
    required this.cutOutSize,
    this.cutOutVerticalOffset = 0,
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

    final centerX = size.width / 2;
    final centerY = size.height / 2 + cutOutVerticalOffset;
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
  bool shouldRepaint(covariant ScanLinePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.isScanning != isScanning ||
      oldDelegate.cutOutSize != cutOutSize ||
      oldDelegate.cutOutVerticalOffset != cutOutVerticalOffset;
}

class ModernQrScannerOverlayShape extends ShapeBorder {
  const ModernQrScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 4.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 20,
    this.borderLength = 40,
    this.cutOutVerticalOffset = 0,
    double? cutOutSize,
  }) : cutOutSize = cutOutSize ?? 280;

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;
  final double cutOutVerticalOffset;

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
    final cutOutCenter = rect.center + Offset(0, cutOutVerticalOffset);
    Path outerPath = Path()..addRect(rect);
    Path cutOutPath =
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: cutOutCenter,
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

    final cutOutCenter = rect.center + Offset(0, cutOutVerticalOffset);
    final innerSize = mCutOutSize - borderOffset * 2;
    final cutOutRect = Rect.fromCenter(
      center: cutOutCenter,
      width: innerSize,
      height: innerSize,
    );

    canvas.drawPath(getOuterPath(rect), backgroundPaint);

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
    cutOutVerticalOffset: cutOutVerticalOffset,
  );
}
