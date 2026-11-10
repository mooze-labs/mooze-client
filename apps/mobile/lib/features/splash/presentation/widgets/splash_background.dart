import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mooze_mobile/themes/motion.dart';

/// Full-bleed liquid glass background of the splash screen.
///
/// The artwork has two ribbons: one in the top part of the canvas and one
/// in the bottom part, with empty space between them. Each ribbon is drawn
/// from the same SVG with a clip, so the two can move on their own.
///
/// The ribbons slide in from the screen edges, then drift and breathe in
/// opposite directions for one ambient cycle and stop. With reduced motion
/// the background is static.
class SplashBackground extends StatefulWidget {
  const SplashBackground({super.key});

  static const assetPath = 'assets/images/splash/background_image.svg';

  @override
  State<SplashBackground> createState() => _SplashBackgroundState();
}

class _SplashBackgroundState extends State<SplashBackground>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _driftController;
  late final Animation<double> _entrance;
  late final Animation<double> _drift;

  bool _started = false;

  /// Distance the ribbons travel while they slide in.
  static const double _entranceOffset = 48.0;

  /// Maximum drift of each ribbon during the ambient cycle.
  static const Offset _driftOffset = Offset(10.0, 14.0);

  /// Extra scale of each ribbon at the peak of the ambient cycle.
  static const double _driftScale = 0.04;

  /// Extra size of the artwork past each screen edge. Each ribbon moves
  /// inside this margin, so the drift never uncovers an edge of the screen.
  /// Keep it larger than both components of [_driftOffset].
  static const double _bleed = 24.0;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: Motion.durationCelebrate,
    );
    _driftController = AnimationController(
      vsync: this,
      duration: Motion.durationAmbient,
    );
    _entrance = CurvedAnimation(
      parent: _entranceController,
      curve: Motion.curveEnter,
    );
    _drift = CurvedAnimation(parent: _driftController, curve: Curves.easeInOut);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (Motion.isReduced(context)) {
      _entranceController.value = 1.0;
      return;
    }

    _entranceController.forward();
    _driftController.forward().then((_) {
      if (mounted) _driftController.reverse();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _driftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final artwork = SvgPicture.asset(
      SplashBackground.assetPath,
      fit: BoxFit.cover,
      alignment: Alignment.center,
    );

    return IgnorePointer(
      child: RepaintBoundary(
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                left: -_bleed,
                top: -_bleed,
                right: -_bleed,
                bottom: -_bleed,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildRibbon(isTop: true, child: artwork),
                    _buildRibbon(isTop: false, child: artwork),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRibbon({required bool isTop, required Widget child}) {
    // The top ribbon comes from above and drifts down and right; the bottom
    // ribbon mirrors it, so the two folds move toward and away from each
    // other like liquid.
    final direction = isTop ? 1.0 : -1.0;

    return AnimatedBuilder(
      animation: Listenable.merge([_entrance, _drift]),
      builder: (context, child) {
        final entranceDy = (1.0 - _entrance.value) * _entranceOffset;
        final drift = _driftOffset * _drift.value;

        return Opacity(
          opacity: _entrance.value,
          child: Transform.translate(
            offset: Offset(
              drift.dx * direction,
              (drift.dy - entranceDy) * direction,
            ),
            child: Transform.scale(
              scale: 1.0 + _driftScale * _drift.value,
              alignment: isTop ? Alignment.topLeft : Alignment.bottomRight,
              child: child,
            ),
          ),
        );
      },
      child: ClipRect(
        clipper: _HalfClipper(isTop: isTop),
        child: child,
      ),
    );
  }
}

/// Clips the artwork to its top or bottom half.
class _HalfClipper extends CustomClipper<Rect> {
  const _HalfClipper({required this.isTop});

  final bool isTop;

  @override
  Rect getClip(Size size) {
    final half = size.height / 2;
    return isTop
        ? Rect.fromLTWH(0, 0, size.width, half)
        : Rect.fromLTWH(0, half, size.width, half);
  }

  @override
  bool shouldReclip(_HalfClipper oldClipper) => oldClipper.isTop != isTop;
}
