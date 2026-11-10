import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Where a transaction is on one step of its track.
enum TxStepState { done, active, failed, upcoming }

/// One step of the status track, such as "On the network".
class TxStep {
  final String label;
  final TxStepState state;

  const TxStep(this.label, this.state);

  bool get reached => state != TxStepState.upcoming;
}

/// The status of a transaction: what state it is in, when it started, and
/// how far it went.
///
/// The card is lit in [color] from its top-left corner: a soft light
/// behind the glyph and a rim that fades along the edges, so the state
/// reads before any text while the card stays glass. The header holds the primary status: a solid disc with the
/// [icon] glyph inside a tinted ring, the status as a title, and the
/// supporting lines below it in muted text. The track under it shows the
/// steps of the transaction from left to right. Reached steps and the
/// lines between them take [color]; the step in progress breathes, unless
/// reduced motion is on.
class TxStatusPanel extends StatelessWidget {
  const TxStatusPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.steps,
    this.details = const [],
  });

  /// Plain glyph drawn on the solid disc, such as a check.
  final IconData icon;
  final String title;
  final Color color;
  final List<TxStep> steps;

  /// Supporting lines under the title, such as the date and the
  /// confirmation count.
  final List<String> details;

  static const double _ringSize = 52;
  static const double _discSize = 30;
  static const BorderRadius _radius = BorderRadius.all(Radius.circular(24));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergeSemantics(
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: _ringSize,
                    height: _ringSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.16),
                      border: Border.all(color: color.withValues(alpha: 0.22)),
                    ),
                    child: Container(
                      width: _discSize,
                      height: _discSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      // Black on the status colors keeps the glyph readable
                      // in both themes.
                      child: Icon(
                        icon,
                        size: 18,
                        color: context.colors.absoluteBlack,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.textTheme.titleMedium?.copyWith(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      for (final line in details) ...[
                        const SizedBox(height: 2),
                        Text(
                          line,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colors.textSecondary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (steps.isNotEmpty) ...[
            const SizedBox(height: 18),
            _Track(steps: steps, color: color),
          ],
        ],
      ),
    );

    // The status color stays in the top-left corner, as a light falling on
    // the card: a radial spot behind the glyph and a rim that is bright
    // there and fades along the edges. The rest of the card stays glass.
    return CustomPaint(
      foregroundPainter: _CornerRimPainter(
        color: color,
        radius: _radius.topLeft.x,
        strength: isDark ? 0.75 : 0.55,
      ),
      child: GlassPanel(
        borderRadius: _radius,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: _radius,
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.6,
                    colors: [
                      color.withValues(alpha: isDark ? 0.40 : 0.24),
                      color.withValues(alpha: isDark ? 0.16 : 0.09),
                      color.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.35, 0.75],
                  ),
                ),
              ),
            ),
            content,
          ],
        ),
      ),
    );
  }
}

/// The rim of the status card: [color] at the top-left corner, fading to
/// nothing along the top and left edges.
class _CornerRimPainter extends CustomPainter {
  _CornerRimPainter({
    required this.color,
    required this.radius,
    required this.strength,
  });

  final Color color;
  final double radius;

  /// Opacity of the rim at the corner.
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = RadialGradient(
        center: Alignment.topLeft,
        radius: 1.2,
        colors: [
          color.withValues(alpha: strength),
          color.withValues(alpha: strength * 0.25),
          color.withValues(alpha: 0),
        ],
        stops: const [0, 0.35, 0.7],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(0.6), Radius.circular(radius)),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CornerRimPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.strength != strength;
}

class _Track extends StatelessWidget {
  const _Track({required this.steps, required this.color});

  final List<TxStep> steps;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final idle = AppSurfaces.hairline(context);
    Color lineColor(bool reached) => reached ? color : idle;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(
            // Each step draws the half lines on its sides, so the lines of
            // neighbouring steps meet between them. A line takes the color
            // once the step it leads to is reached.
            child: Semantics(
              label: steps[i].label,
              value: steps[i].state.name,
              excludeSemantics: true,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: i == 0
                            ? const SizedBox.shrink()
                            : _Line(
                                color: lineColor(steps[i].reached),
                                gapAtEnd: true,
                              ),
                      ),
                      _Node(state: steps[i].state, color: color),
                      Expanded(
                        child: i == steps.length - 1
                            ? const SizedBox.shrink()
                            : _Line(
                                color: lineColor(steps[i + 1].reached),
                                gapAtEnd: false,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    steps[i].label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: steps[i].reached
                          ? context.colors.textPrimary
                          : context.colors.textSecondary,
                      fontWeight: steps[i].reached
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Half of the line between two steps. It keeps a gap only on the side of
/// its node, so two halves meet without a break.
class _Line extends StatelessWidget {
  const _Line({required this.color, required this.gapAtEnd});

  final Color color;

  /// True for the half before a node, false for the half after it.
  final bool gapAtEnd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: gapAtEnd ? 0 : 4,
        end: gapAtEnd ? 4 : 0,
      ),
      child: AnimatedContainer(
        duration: Motion.of(context, Motion.durationEmphasis),
        curve: Motion.curveMove,
        height: 2,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({required this.state, required this.color});

  final TxStepState state;
  final Color color;

  static const double size = 22;

  @override
  Widget build(BuildContext context) {
    // Black on the status colors keeps the glyph readable in both themes.
    final onColor = context.colors.absoluteBlack;
    return switch (state) {
      TxStepState.done => _disc(
        Icon(Icons.check_rounded, size: 14, color: onColor),
      ),
      TxStepState.failed => _disc(
        Icon(Icons.close_rounded, size: 14, color: onColor),
      ),
      TxStepState.active => _ActiveNode(color: color),
      TxStepState.upcoming => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppSurfaces.hairline(context), width: 2),
        ),
      ),
    };
  }

  Widget _disc(Widget child) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 8),
      ],
    ),
    child: child,
  );
}

/// The step in progress: a ring in the status color around a dot that
/// breathes slowly. Reduced motion shows the dot still.
class _ActiveNode extends StatefulWidget {
  const _ActiveNode({required this.color});

  final Color color;

  @override
  State<_ActiveNode> createState() => _ActiveNodeState();
}

class _ActiveNodeState extends State<_ActiveNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.durationAmbient,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.isReduced(context)) {
      _controller
        ..stop()
        ..value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    return Container(
      width: _Node.size,
      height: _Node.size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color, width: 2),
      ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.35, end: 1).animate(
          CurvedAnimation(parent: _controller, curve: Motion.curveMove),
        ),
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}
