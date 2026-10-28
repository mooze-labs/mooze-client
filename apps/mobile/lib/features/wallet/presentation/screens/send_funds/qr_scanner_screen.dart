import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_status_view.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/press_scale.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/send_funds/payment_request_applier.dart';
import '../../providers/send_funds/qr_validation_service.dart';
import 'package:mooze_mobile/shared/widgets.dart';

/// Camera step of the send flow.
///
/// The preview fills the screen. A shade with a square hole and four corner
/// marks shows where to hold the code. A status pill, the hint, and the
/// flash and camera buttons sit on glass at the bottom. The chrome is
/// still: it has no scan line or other looping motion.
///
/// When the camera fails or its access is blocked, the screen shows the
/// backdrop with a message and a way out.
class QRCodeScannerScreen extends ConsumerStatefulWidget {
  const QRCodeScannerScreen({super.key});

  @override
  ConsumerState<QRCodeScannerScreen> createState() =>
      _QRCodeScannerScreenState();
}

class _QRCodeScannerScreenState extends ConsumerState<QRCodeScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool isFlashOn = false;
  bool isScanning = true;

  @override
  void dispose() {
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

    PaymentRequestApplier.apply(ref, validationResult.cleanedData ?? data);

    context.pop();
  }

  void _toggleFlash() {
    setState(() {
      isFlashOn = !isFlashOn;
    });
    cameraController.toggleTorch();
  }

  /// Returns the side of the scan window for the free area [width] ×
  /// [height].
  double _computeCutOutSize(double width, double height) {
    final minSide = width < height ? width : height;
    return (minSide * 0.72).clamp(200.0, 300.0);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    // The chrome follows the camera state: a failed camera shows the
    // backdrop and a message instead of the preview chrome.
    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: cameraController,
      builder: (context, cameraState, _) {
        final hasError = cameraState.error != null;
        return Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: _CameraColors.background,
          appBar: hasError
              ? BackdropAppBar(title: Text(t.wallet_send_address_scan_qr))
              : AppBar(
                  title: Text(
                    t.wallet_send_address_scan_qr,
                    style: context.textTheme.titleMedium?.copyWith(
                      color: _CameraColors.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  foregroundColor: _CameraColors.foreground,
                  iconTheme: const IconThemeData(
                    color: _CameraColors.foreground,
                  ),
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  // The preview is dark in both themes.
                  systemOverlayStyle: SystemUiOverlayStyle.light,
                ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isLandscape = constraints.maxWidth > constraints.maxHeight;
              return isLandscape
                  ? _buildLandscapeLayout(context, constraints, hasError)
                  : _buildPortraitLayout(context, constraints, hasError);
            },
          ),
        );
      },
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    BoxConstraints constraints,
    bool hasError,
  ) {
    final mediaPadding = MediaQuery.of(context).padding;
    final topReserve = mediaPadding.top + kToolbarHeight;
    final bottomReserve = 250.0 + mediaPadding.bottom;
    final availableHeight = (constraints.maxHeight - topReserve - bottomReserve)
        .clamp(200.0, double.infinity);
    final side = _computeCutOutSize(constraints.maxWidth, availableHeight);
    final window = Rect.fromCenter(
      center: Offset(
        constraints.maxWidth / 2,
        topReserve + availableHeight / 2,
      ),
      width: side,
      height: side,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildScanner(),
        if (!hasError) ...[
          _buildFrame(window),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: _buildControls(context),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    BoxConstraints constraints,
    bool hasError,
  ) {
    final mediaPadding = MediaQuery.of(context).padding;
    const sidePanelWidth = 300.0;
    final cameraAreaWidth =
        (constraints.maxWidth - sidePanelWidth - mediaPadding.right).clamp(
          240.0,
          double.infinity,
        );
    final top = mediaPadding.top + kToolbarHeight;
    final availableHeight = (constraints.maxHeight - top).clamp(
      180.0,
      double.infinity,
    );
    final side = _computeCutOutSize(cameraAreaWidth, availableHeight);
    final window = Rect.fromCenter(
      center: Offset(cameraAreaWidth / 2, top + availableHeight / 2),
      width: side,
      height: side,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildScanner(),
        if (!hasError) ...[
          _buildFrame(window),
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: sidePanelWidth + mediaPadding.right,
            child: SafeArea(
              left: false,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildControls(context),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildScanner() {
    return MobileScanner(
      controller: cameraController,
      onDetect: _onDetect,
      fit: BoxFit.cover,
      placeholderBuilder: _buildScannerPlaceholder,
      errorBuilder: _buildScannerError,
    );
  }

  /// The shade and the corner marks. They are decoration, so taps reach the
  /// preview.
  Widget _buildFrame(Rect window) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ScanWindowPainter(
          window: window,
          markColor: isScanning
              ? _CameraColors.foreground
              : context.colors.positiveColor,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildScannerPlaceholder(BuildContext context) {
    return ColoredBox(
      color: _CameraColors.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: _CameraColors.foreground,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).qr_scanner_searching,
              style: context.textTheme.bodyMedium?.copyWith(
                color: _CameraColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerError(
    BuildContext context,
    MobileScannerException error,
  ) {
    final t = AppLocalizations.of(context);
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return _CameraMessage(
      title: denied
          ? t.pix_hub_scan_permission_title
          : t.pix_hub_scan_unavailable_title,
      message: denied
          ? t.pix_hub_scan_permission_body
          : error.errorDetails?.message ?? t.qr_scanner_position_hint,
      action: denied
          ? PrimaryButton(
              text: t.pix_hub_scan_open_settings,
              onPressed: openAppSettings,
            )
          : PrimaryButton(text: t.common_back, onPressed: () => context.pop()),
    );
  }

  Widget _buildControls(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatusPill(found: !isScanning),
        const SizedBox(height: 14),
        Text(
          t.qr_scanner_position_hint,
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(
            color: _CameraColors.foreground,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          t.qr_scanner_supported_networks,
          textAlign: TextAlign.center,
          style: context.textTheme.bodySmall?.copyWith(
            color: _CameraColors.muted,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: _GlassCircleButton(
                icon: PixIcons.fast,
                label: t.qr_scanner_flash_label,
                isActive: isFlashOn,
                onTap: _toggleFlash,
              ),
            ),
            const SizedBox(width: 32),
            Flexible(
              child: _GlassCircleButton(
                icon: PixIcons.refresh,
                label: t.qr_scanner_camera_label,
                onTap: () => cameraController.switchCamera(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Colors of the camera area.
///
/// The preview is dark in both themes, so its chrome uses fixed light
/// colors instead of the theme text colors.
abstract final class _CameraColors {
  static const background = Colors.black;
  static const foreground = Colors.white;
  static const muted = Colors.white70;

  /// Shade over the preview outside the scan window.
  static final scrim = Colors.black.withValues(alpha: 0.55);
}

/// "Searching for a QR code" or "QR code found" on a glass pill.
///
/// The icon changes with the text, and screen readers announce the change.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.found});

  final bool found;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final color = found
        ? context.colors.positiveColor
        : context.colors.textPrimary;
    return LiquidGlass(
      blurBackdrop: false,
      opaque: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
        child: AnimatedSwitcher(
          duration: Motion.of(context, Motion.durationFast),
          child: Row(
            key: ValueKey(found),
            mainAxisSize: MainAxisSize.min,
            children: [
              PixIcon(
                found ? PixIcons.success : PixIcons.scan,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    found ? t.qr_scanner_found : t.qr_scanner_searching,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelLarge?.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A round glass button with a label below it.
///
/// An active toggle, such as the flash, fills the circle with white and
/// draws the icon dark. Screen readers read the toggle state.
class _GlassCircleButton extends StatelessWidget {
  const _GlassCircleButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive,
  });

  final PixIconData icon;
  final String label;
  final VoidCallback onTap;

  /// The toggle state. Null for a plain button.
  final bool? isActive;

  static const double _size = 56;

  @override
  Widget build(BuildContext context) {
    final active = isActive ?? false;
    const shape = CircleBorder();
    final iconColor = active
        ? _CameraColors.background
        : context.colors.textPrimary;

    final circle = active
        ? const DecoratedBox(
            decoration: ShapeDecoration(
              shape: shape,
              color: _CameraColors.foreground,
            ),
            child: SizedBox.square(dimension: _size),
          )
        : const SizedBox.square(
            dimension: _size,
            child: LiquidGlass(
              blurBackdrop: false,
              opaque: true,
              child: SizedBox.expand(),
            ),
          );

    return Semantics(
      button: true,
      toggled: isActive,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PressScale(
            scale: Motion.pressScaleCircle,
            child: SizedBox.square(
              dimension: _size,
              child: Stack(
                children: [
                  circle,
                  Material(
                    type: MaterialType.transparency,
                    shape: shape,
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: onTap,
                      customBorder: shape,
                      child: Center(
                        child: PixIcon(icon, size: 24, color: iconColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelMedium?.copyWith(
              color: _CameraColors.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown in place of the preview when the camera fails or its access is
/// blocked: the backdrop, a camera icon with a slash, a title, a message,
/// and one action.
class _CameraMessage extends StatelessWidget {
  const _CameraMessage({
    required this.title,
    required this.message,
    required this.action,
  });

  final String title;
  final String message;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const AppBackdrop(),
        SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const PixIconWell(
                          icon: PixIcons.cameraOff,
                          tone: PixTone.warning,
                          size: PixStatusView.emblemSize,
                        ),
                        const SizedBox(height: 24),
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            style: context.textTheme.headlineSmall?.copyWith(
                              color: context.colors.textPrimary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.colors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: action,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Paints the shade outside the scan window and the four corner marks.
class _ScanWindowPainter extends CustomPainter {
  const _ScanWindowPainter({required this.window, required this.markColor});

  final Rect window;
  final Color markColor;

  static const double _windowRadius = 24;
  static const double _markLength = 34;
  static const double _markWidth = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final rounded = RRect.fromRectAndRadius(
      window,
      const Radius.circular(_windowRadius),
    );

    // The shade covers the preview with a hole for the scan window.
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & size)
        ..addRRect(rounded),
      Paint()..color = _CameraColors.scrim,
    );

    final mark = Paint()
      ..color = markColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _markWidth
      ..strokeCap = StrokeCap.round;
    const r = _windowRadius;
    const l = _markLength;
    final corners = [
      // Top left, top right, bottom right, bottom left.
      (window.topLeft, 1.0, 1.0),
      (window.topRight, -1.0, 1.0),
      (window.bottomRight, -1.0, -1.0),
      (window.bottomLeft, 1.0, -1.0),
    ];
    for (final (corner, dx, dy) in corners) {
      // Each mark follows the round corner, then runs straight along the
      // two edges.
      final path = Path()
        ..moveTo(corner.dx, corner.dy + dy * l)
        ..lineTo(corner.dx, corner.dy + dy * r)
        ..quadraticBezierTo(corner.dx, corner.dy, corner.dx + dx * r, corner.dy)
        ..lineTo(corner.dx + dx * l, corner.dy);
      canvas.drawPath(path, mark);
    }
  }

  @override
  bool shouldRepaint(_ScanWindowPainter oldDelegate) =>
      oldDelegate.window != window || oldDelegate.markColor != markColor;
}
