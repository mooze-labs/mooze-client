import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mooze_mobile/features/pix/hub/domain/validation/pix_br_code.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_send_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_labels.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_screen_scaffold.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_status_view.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/app_backdrop.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:permission_handler/permission_handler.dart';

/// Camera step of the send flow.
///
/// A scanned code goes through the same local checks as a pasted one. When the
/// camera is unavailable, the screen points to Pix Copy and Paste.
///
/// The preview sits in a dark rounded window on the page backdrop. A shade
/// with a square hole and four corner marks shows where to hold the code.
/// The chrome is still: it has no scan line or other looping motion.
class PixSendScanScreen extends ConsumerStatefulWidget {
  const PixSendScanScreen({super.key});

  @override
  ConsumerState<PixSendScanScreen> createState() => _PixSendScanScreenState();
}

/// What the screen can show while the camera is set up.
enum _ScanStage { checking, ready, denied }

class _PixSendScanScreenState extends ConsumerState<PixSendScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  _ScanStage _stage = _ScanStage.checking;

  /// True while a code is being handled, so the screen starts one flow only.
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    _requestCamera();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _requestCamera() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(
      () => _stage = status.isGranted ? _ScanStage.ready : _ScanStage.denied,
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final value = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .firstWhere((raw) => raw != null && raw.isNotEmpty, orElse: () => null);
    if (value == null) return;

    await _submitCode(value, scanned: true);
  }

  Future<void> _submitCode(String code, {required bool scanned}) async {
    // One code at a time: the camera reports continuously.
    if (_handled) return;
    _handled = true;

    final t = AppLocalizations.of(context);
    final parsed = PixBrCodeParser.parse(code);

    if (!parsed.isStructurallyValid) {
      _handled = false;
      AppSnackBar.error(context, pixBrCodeErrorMessage(t, parsed.error!));
      return;
    }

    final failure = ref
        .read(pixSendControllerProvider.notifier)
        .startFromCode(code, scanned: scanned);
    if (failure != null) {
      _handled = false;
      AppSnackBar.error(context, pixHubFailureMessage(t, failure));
      return;
    }

    // The amount step also asks for the tax ID of the key owner, so a code
    // with a fixed amount passes through it too.
    await context.push('/pix/send/amount');
    // Back on this screen: accept the next code.
    if (mounted) _handled = false;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final denied = _stage == _ScanStage.denied;

    return Scaffold(
      // The app bar is clear and paints its slice of the backdrop, so the
      // bar and the page read as one surface.
      extendBodyBehindAppBar: true,
      appBar: BackdropAppBar(title: Text(t.pix_hub_send_title)),
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackdrop()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PixScreenTitle(
                    title: t.pix_hub_method_qr,
                    subtitle: denied
                        ? null
                        : t.pix_hub_send_method_qr_description,
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: Motion.of(context, Motion.durationBase),
                      switchInCurve: Motion.curveEnter,
                      switchOutCurve: Motion.curveExit,
                      child: _buildStage(context),
                    ),
                  ),
                  if (denied) ...[
                    const SizedBox(height: 12),
                    PrimaryButton(
                      text: t.pix_hub_scan_open_settings,
                      onPressed: openAppSettings,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStage(BuildContext context) {
    final t = AppLocalizations.of(context);
    switch (_stage) {
      case _ScanStage.checking:
        // The window shows while the permission request runs, so the layout
        // does not move when the camera starts.
        return const _Viewfinder(
          key: ValueKey(_ScanStage.checking),
          child: _CameraStarting(),
        );
      case _ScanStage.denied:
        return _ScanMessage(
          key: const ValueKey(_ScanStage.denied),
          title: t.pix_hub_scan_permission_title,
          message: t.pix_hub_scan_permission_body,
        );
      case _ScanStage.ready:
        return _Viewfinder(
          key: const ValueKey(_ScanStage.ready),
          child: MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            fit: BoxFit.cover,
            placeholderBuilder: (context) => const _CameraStarting(),
            // The scanner draws the overlay over a running preview only, so
            // the marks never cover the error message.
            overlayBuilder: (context, constraints) => const IgnorePointer(
              child: SizedBox.expand(
                child: CustomPaint(painter: _ScanWindowPainter()),
              ),
            ),
            errorBuilder: (context, error) => _CameraUnavailable(
              title: AppLocalizations.of(
                context,
              ).pix_hub_scan_unavailable_title,
              message:
                  error.errorDetails?.message ??
                  AppLocalizations.of(context).pix_hub_scan_unavailable_body,
            ),
          ),
        );
    }
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
  static final scrim = Colors.black.withValues(alpha: 0.45);
}

/// The dark camera window that holds the preview.
class _Viewfinder extends StatelessWidget {
  final Widget child;

  const _Viewfinder({super.key, required this.child});

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(28));

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      // The hairline separates the dark window from a dark backdrop.
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: _radius,
        border: Border.all(color: AppSurfaces.hairline(context)),
      ),
      child: ClipRRect(
        borderRadius: _radius,
        child: ColoredBox(
          color: _CameraColors.background,
          child: SizedBox.expand(child: child),
        ),
      ),
    );
  }
}

/// The camera window while the camera starts: a small spinner.
class _CameraStarting extends StatelessWidget {
  const _CameraStarting();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _CameraColors.background,
      child: Center(
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: _CameraColors.foreground,
            // A still arc when animations are off.
            value: Motion.isReduced(context) ? 0.7 : null,
          ),
        ),
      ),
    );
  }
}

/// Paints the shade outside the scan window and the four corner marks.
class _ScanWindowPainter extends CustomPainter {
  const _ScanWindowPainter();

  /// Part of the shorter side that the scan window takes.
  static const double _windowFactor = 0.68;
  static const double _maxWindow = 280;
  static const double _windowRadius = 24;
  static const double _markLength = 44;
  static const double _markWidth = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final side = (size.shortestSide * _windowFactor).clamp(0.0, _maxWindow);
    final window = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: side,
      height: side,
    );
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
      ..color = _CameraColors.foreground
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
  bool shouldRepaint(_ScanWindowPainter oldDelegate) => false;
}

/// Shown in the camera window when the camera fails to start.
class _CameraUnavailable extends StatelessWidget {
  final String title;
  final String message;

  const _CameraUnavailable({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _CameraColors.background,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _CameraColors.foreground.withValues(alpha: 0.1),
                  border: Border.all(
                    color: _CameraColors.foreground.withValues(alpha: 0.2),
                  ),
                ),
                child: const PixIcon(
                  PixIcons.cameraOff,
                  size: 28,
                  color: _CameraColors.foreground,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: context.textTheme.titleMedium?.copyWith(
                  color: _CameraColors.foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: _CameraColors.muted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown in place of the camera window when the camera access is blocked.
///
/// The camera icon with a slash, the title, and the message carry the
/// state. The screen pins the way out, "Open settings", at the bottom.
class _ScanMessage extends StatelessWidget {
  final String title;
  final String message;

  const _ScanMessage({super.key, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
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
    );
  }
}
