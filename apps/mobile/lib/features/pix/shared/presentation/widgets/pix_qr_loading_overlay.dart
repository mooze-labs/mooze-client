import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_effects.dart';
import 'package:mooze_mobile/shared/widgets/stage/stage_palette.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

import 'pix_qr_scene.dart';

/// Covers the screen while a Pix QR code is created, with the scene of a
/// code that assembles and is scanned until the request ends, see
/// [PixQrScene].
///
/// [show] opens the stage from the bottom of the screen, where the main
/// button sits, and the code assembles. The caller then ends it:
/// - [succeed] once the code exists: the code locks in with a flash, the
///   next screen opens under the scene halfway through, and the scene fades
///   away to uncover it;
/// - [fail] once the request fails: the scene fades away at once.
///
/// The scene blocks taps and screen readers below it. After [slowAfter] its
/// caption adds a line, so a stalled request does not look frozen. Under
/// reduced motion nothing moves, and [succeed] opens the next screen at
/// once.
///
/// The scene lives in the overlay, not in the screen that shows it, so it
/// can outlive that screen while it uncovers the next one.
class PixQrLoadingOverlay {
  PixQrLoadingOverlay._();

  /// Time after which the caption says the request takes longer.
  static const slowAfter = Duration(seconds: 15);

  /// Time the code takes to assemble, once the stage covers the screen.
  static const assembleDuration = Duration(milliseconds: 1000);

  final _outcome = Completer<VoidCallback?>();
  final _closed = Completer<void>();
  OverlayEntry? _entry;

  /// Covers the screen of [context] with the scene, captioned [text].
  static PixQrLoadingOverlay show(
    BuildContext context, {
    required String text,
  }) {
    final loading = PixQrLoadingOverlay._();
    final entry = OverlayEntry(
      builder: (_) => _PixQrLoadingView(
        text: text,
        outcome: loading._outcome.future,
        onClosed: loading._remove,
      ),
    );
    loading._entry = entry;
    Overlay.of(context).insert(entry);
    return loading;
  }

  /// Ends the scene with the code ready. [openNext] opens the next screen
  /// under the scene. Completes once the scene has gone.
  Future<void> succeed(VoidCallback openNext) {
    if (!_outcome.isCompleted) _outcome.complete(openNext);
    return _closed.future;
  }

  /// Ends the scene without a code. Completes once the scene has gone.
  Future<void> fail() {
    if (!_outcome.isCompleted) _outcome.complete(null);
    return _closed.future;
  }

  /// Removes the scene at once if it still waits for the request, for
  /// example when the screen below it closes. A scene that is ending
  /// finishes by itself.
  void cancel() {
    if (!_outcome.isCompleted) _remove();
  }

  void _remove() {
    _entry?.remove();
    _entry = null;
    if (!_closed.isCompleted) _closed.complete();
  }
}

class _PixQrLoadingView extends StatefulWidget {
  const _PixQrLoadingView({
    required this.text,
    required this.outcome,
    required this.onClosed,
  });

  final String text;

  /// Completes with the opening of the next screen, or with null when the
  /// request failed.
  final Future<VoidCallback?> outcome;

  final VoidCallback onClosed;

  @override
  State<_PixQrLoadingView> createState() => _PixQrLoadingViewState();
}

class _PixQrLoadingViewState extends State<_PixQrLoadingView>
    with TickerProviderStateMixin {
  /// The stage opening from the bottom of the screen.
  late final AnimationController _open = AnimationController(
    vsync: this,
    duration: Motion.durationSlow,
  );
  late final AnimationController _assemble = AnimationController(
    vsync: this,
    duration: PixQrLoadingOverlay.assembleDuration,
  );

  /// The slow cycle of the scan while the request runs.
  late final AnimationController _cycle = AnimationController(
    vsync: this,
    duration: Motion.durationAmbient,
  );

  /// The waiting motion fading in, and out once the code is ready.
  late final AnimationController _waiting = AnimationController(
    vsync: this,
    duration: Motion.durationSlow,
  );
  late final AnimationController _finale = AnimationController(
    vsync: this,
    duration: Motion.durationCelebrate,
  );

  /// The scene fading away.
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: Motion.durationSlow,
  );

  late final Listenable _motion = Listenable.merge([
    _open,
    _assemble,
    _cycle,
    _waiting,
    _finale,
    _exit,
  ]);

  /// Completes once the code has assembled.
  final _entered = Completer<void>();

  Timer? _slowTimer;
  bool _slow = false;
  bool _still = false;
  bool _started = false;
  bool _ending = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _still = Motion.isReduced(context);
    _slowTimer = Timer(PixQrLoadingOverlay.slowAfter, () {
      if (mounted) setState(() => _slow = true);
    });
    widget.outcome.then(_end);
    _enter();
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    _open.dispose();
    _assemble.dispose();
    _cycle.dispose();
    _waiting.dispose();
    _finale.dispose();
    _exit.dispose();
    super.dispose();
  }

  /// Opens the stage, then assembles the code, which the beam then scans
  /// until the request ends.
  Future<void> _enter() async {
    if (_still) {
      _open.value = 1;
      _assemble.value = 1;
      _entered.complete();
      return;
    }
    await _open.forward();
    if (!mounted) return;
    HapticFeedback.lightImpact();
    await _assemble.forward();
    if (!mounted) return;
    _entered.complete();
    if (_ending) return;
    _cycle.repeat();
    _waiting.forward();
  }

  /// Ends the scene: with [openNext] once the code has assembled and locks
  /// in, or at once without it.
  Future<void> _end(VoidCallback? openNext) async {
    if (!mounted) return;
    _ending = true;
    _slowTimer?.cancel();
    if (openNext == null) {
      for (final controller in [_open, _assemble, _cycle, _waiting]) {
        controller.stop();
      }
      if (!_still) {
        await _exit.animateTo(1, duration: Motion.durationExit);
      }
      if (mounted) widget.onClosed();
      return;
    }
    await _entered.future;
    if (!mounted) return;
    _cycle.stop();
    if (_still) {
      HapticFeedback.lightImpact();
      openNext();
      widget.onClosed();
      return;
    }
    HapticFeedback.heavyImpact();
    _waiting.animateBack(0, duration: Motion.durationFast);
    // The next screen opens under the scene while the code still glows,
    // so its own entrance is done once the scene fades.
    await _finale.animateTo(0.5);
    if (!mounted) return;
    openNext();
    await _finale.forward();
    if (!mounted) return;
    await _exit.forward();
    if (mounted) widget.onClosed();
  }

  @override
  Widget build(BuildContext context) {
    final palette = StagePalette.of(context);
    final brand = context.colors.primaryColor;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: palette.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: AnimatedBuilder(
        animation: _motion,
        builder: (context, _) {
          final open = Curves.easeInOutCubic.transform(_open.value);
          // The scene fades through its page: the code dissolves first,
          // then the page, so it never shows over the code of the next
          // screen.
          final vanish = Curves.easeIn.transform(
            stageProgress(_exit.value, 0, 0.55),
          );
          final uncover = Motion.curveExit.transform(
            stageProgress(_exit.value, 0.45, 1),
          );
          final motion = PixQrMotion(
            assemble: _assemble.value,
            cycle: _cycle.value,
            waiting: Curves.easeInOut.transform(_waiting.value),
            finale: _finale.value,
          );
          final caption =
              stageProgress(motion.assemble, 0.4, 0.8) *
              (1 - stageProgress(motion.finale, 0, 0.3));
          // Taps reach the next screen once the scene fades.
          return IgnorePointer(
            ignoring: _exit.value > 0,
            child: AbsorbPointer(
              child: BlockSemantics(
                child: Opacity(
                  opacity: 1 - uncover,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipPath(
                        clipper: _Iris(open),
                        child: ColoredBox(
                          color: palette.page,
                          child: Material(
                            type: MaterialType.transparency,
                            child: SafeArea(
                              child: Center(
                                child: Opacity(
                                  opacity: 1 - vanish,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Transform.scale(
                                        scale: 1 + 0.08 * vanish,
                                        child: PixQrScene(motion: motion),
                                      ),
                                      const SizedBox(height: 36),
                                      Opacity(
                                        opacity: caption,
                                        child: _Caption(
                                          text: widget.text,
                                          slow: _slow,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (open > 0 && open < 1)
                        IgnorePointer(
                          child: CustomPaint(painter: _IrisRim(open, brand)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The step under the code, with a second line once the request takes
/// longer.
class _Caption extends StatelessWidget {
  const _Caption({required this.text, required this.slow});

  final String text;
  final bool slow;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: context.textTheme.titleMedium?.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          AnimatedSize(
            duration: Motion.of(context, Motion.durationBase),
            curve: Motion.curveMove,
            child: slow
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      t.common_taking_longer,
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// The circle of the stage at [progress] on a screen of [size]: it grows
/// from the bottom of the screen, where the main button sits, until it
/// reaches the top corners.
({Offset center, double radius}) _irisAt(Size size, double progress) {
  final center = Offset(size.width / 2, size.height - 56);
  final reach = math.sqrt(math.pow(size.width / 2, 2) + math.pow(center.dy, 2));
  return (center: center, radius: reach * progress);
}

class _Iris extends CustomClipper<Path> {
  const _Iris(this.progress);

  final double progress;

  @override
  Path getClip(Size size) {
    if (progress >= 1) return Path()..addRect(Offset.zero & size);
    final iris = _irisAt(size, progress);
    return Path()
      ..addOval(Rect.fromCircle(center: iris.center, radius: iris.radius));
  }

  @override
  bool shouldReclip(_Iris oldClipper) => oldClipper.progress != progress;
}

/// A ring of brand light on the edge of the growing stage.
class _IrisRim extends CustomPainter {
  const _IrisRim(this.progress, this.brand);

  final double progress;
  final Color brand;

  @override
  void paint(Canvas canvas, Size size) {
    final iris = _irisAt(size, progress);
    final strength = math.sin(math.pi * progress);
    canvas
      ..drawCircle(
        iris.center,
        iris.radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..color = brand.withValues(alpha: 0.35 * strength)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      )
      ..drawCircle(
        iris.center,
        iris.radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = brand.withValues(alpha: 0.9 * strength),
      );
  }

  @override
  bool shouldRepaint(_IrisRim oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.brand != brand;
}
