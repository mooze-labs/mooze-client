import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_status_view.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/shared/widgets/buttons.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/shared/widgets/motion/press_scale.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:permission_handler/permission_handler.dart';

/// Camera screen that reads a QR code, shared by the scan steps of the app.
///
/// The preview fills the screen. A shade with a square hole and four corner
/// marks shows where to hold the code. A status pill, the hint, and the
/// flash and camera buttons sit on glass at the bottom. The chrome is
/// still: it has no scan line or other looping motion.
///
/// When the camera fails or its access is blocked, the screen shows the
/// backdrop with a message and a way out.
///
/// The view only reads codes. The screen that hosts it checks them, and
/// reports with [found] that it is handling one.
class QrScannerView extends StatefulWidget {
  const QrScannerView({
    super.key,
    required this.title,
    required this.hint,
    required this.found,
    this.onCode,
    this.onBarcode,
    this.detail,
    this.unavailableMessage,
    this.unavailableAction,
    this.detectionSpeed = DetectionSpeed.normal,
    this.controller,
    this.debugPreview,
  }) : assert(onCode != null || onBarcode != null);

  /// Title of the app bar.
  final String title;

  /// Main line below the status pill.
  final String hint;

  /// Muted line below [hint], for example the networks that the scan reads.
  final String? detail;

  /// True while the host screen handles a code. The pill reads "found", the
  /// corner marks turn green, and the view reports no other code.
  final bool found;

  /// Receives the text of a code that the camera read.
  final ValueChanged<String>? onCode;

  /// Receives the whole code in place of [onCode], for a host that reads
  /// binary codes, which can have bytes and no text.
  final ValueChanged<Barcode>? onBarcode;

  /// The first of [barcodes] with text or bytes.
  @visibleForTesting
  static Barcode? readableBarcode(List<Barcode> barcodes) {
    for (final barcode in barcodes) {
      if ((barcode.rawValue?.isNotEmpty ?? false) ||
          (barcode.rawBytes?.isNotEmpty ?? false)) {
        return barcode;
      }
    }
    return null;
  }

  /// Message when the camera fails for a reason other than a blocked access
  /// and the error carries no message. Null shows the position hint.
  final String? unavailableMessage;

  /// Way out when the camera fails for a reason other than a blocked access.
  /// Null shows a back button.
  final Widget? unavailableAction;

  /// Used when the view creates its own controller.
  final DetectionSpeed detectionSpeed;

  /// Camera of the view. The view creates and disposes its own when null;
  /// a given controller stays with its owner.
  final MobileScannerController? controller;

  /// Stands in for the camera preview in tests, which have no camera. Screens
  /// pass it through from their own test seam only.
  final Widget? debugPreview;

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  late final MobileScannerController _controller =
      widget.controller ??
      MobileScannerController(detectionSpeed: widget.detectionSpeed);
  bool _isFlashOn = false;

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (widget.found) return;
    if (widget.onBarcode case final onBarcode?) {
      final barcode = QrScannerView.readableBarcode(capture.barcodes);
      if (barcode != null) onBarcode(barcode);
      return;
    }
    final value = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .firstWhere((raw) => raw != null && raw.isNotEmpty, orElse: () => null);
    if (value != null) widget.onCode?.call(value);
  }

  void _toggleFlash() {
    setState(() => _isFlashOn = !_isFlashOn);
    _controller.toggleTorch();
  }

  /// Returns the side of the scan window for the free area [width] ×
  /// [height].
  double _computeCutOutSize(double width, double height) {
    final minSide = width < height ? width : height;
    return (minSide * 0.72).clamp(200.0, 300.0);
  }

  @override
  Widget build(BuildContext context) {
    // The chrome follows the camera state: a failed camera shows the
    // backdrop and a message instead of the preview chrome.
    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: _controller,
      builder: (context, cameraState, _) {
        final error = cameraState.error;
        return Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: _CameraColors.background,
          appBar: error != null
              ? BackdropAppBar(title: Text(widget.title))
              : AppBar(
                  title: Text(
                    widget.title,
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
              return Stack(
                fit: StackFit.expand,
                children: [
                  // The preview stays mounted under the message, so the
                  // scanner can restart the camera when the app resumes.
                  _buildScanner(),
                  if (error != null)
                    _buildError(context, error)
                  else if (isLandscape)
                    ..._buildLandscapeChrome(context, constraints)
                  else
                    ..._buildPortraitChrome(context, constraints),
                ],
              );
            },
          ),
        );
      },
    );
  }

  List<Widget> _buildPortraitChrome(
    BuildContext context,
    BoxConstraints constraints,
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

    return [
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
    ];
  }

  List<Widget> _buildLandscapeChrome(
    BuildContext context,
    BoxConstraints constraints,
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

    return [
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
    ];
  }

  Widget _buildScanner() {
    return widget.debugPreview ??
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          fit: BoxFit.cover,
          placeholderBuilder: _buildScannerPlaceholder,
          // The view covers the preview with its message on an error, so
          // the preview area only stays dark meanwhile.
          errorBuilder: (_, _) =>
              const ColoredBox(color: _CameraColors.background),
        );
  }

  /// The shade and the corner marks. They are decoration, so taps reach the
  /// preview.
  Widget _buildFrame(Rect window) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ScanWindowPainter(
          window: window,
          markColor: widget.found
              ? context.colors.positiveColor
              : _CameraColors.foreground,
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

  Widget _buildError(BuildContext context, MobileScannerException error) {
    final t = AppLocalizations.of(context);
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return _CameraMessage(
      title: denied
          ? t.pix_hub_scan_permission_title
          : t.pix_hub_scan_unavailable_title,
      message: denied
          ? t.pix_hub_scan_permission_body
          : error.errorDetails?.message ??
                widget.unavailableMessage ??
                t.qr_scanner_position_hint,
      action: denied
          ? PrimaryButton(
              text: t.pix_hub_scan_open_settings,
              onPressed: openAppSettings,
            )
          : widget.unavailableAction ??
                PrimaryButton(
                  text: t.common_back,
                  onPressed: () => context.pop(),
                ),
    );
  }

  Widget _buildControls(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatusPill(found: widget.found),
        const SizedBox(height: 14),
        Text(
          widget.hint,
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(
            color: _CameraColors.foreground,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (widget.detail case final detail?) ...[
          const SizedBox(height: 4),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(
              color: _CameraColors.muted,
            ),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: _GlassCircleButton(
                icon: PixIcons.fast,
                label: t.qr_scanner_flash_label,
                isActive: _isFlashOn,
                onTap: _toggleFlash,
              ),
            ),
            const SizedBox(width: 32),
            Flexible(
              child: _GlassCircleButton(
                icon: PixIcons.refresh,
                label: t.qr_scanner_camera_label,
                onTap: () => _controller.switchCamera(),
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
