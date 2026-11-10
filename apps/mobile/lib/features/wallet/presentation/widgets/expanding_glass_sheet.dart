import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';
import 'package:mooze_mobile/themes/motion.dart';

/// Marks the widget that an expanding glass sheet grows out of.
///
/// [showExpandingGlassSheet] finds the nearest origin above its context and
/// grows the sheet out of its bounds. The origin itself never changes: it
/// stays in place, visible, and looks as before, without a highlight.
/// [borderRadius] is the corner radius of [child], where the sheet starts
/// and ends.
class GlassSheetOrigin extends StatefulWidget {
  const GlassSheetOrigin({
    super.key,
    required this.child,
    this.borderRadius = BorderRadius.zero,
  });

  final Widget child;
  final BorderRadius borderRadius;

  /// Returns the nearest origin above [context], or null.
  static GlassSheetOriginState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<GlassSheetOriginState>();

  @override
  State<GlassSheetOrigin> createState() => GlassSheetOriginState();
}

class GlassSheetOriginState extends State<GlassSheetOrigin> {
  /// Returns the bounds of the origin in the coordinates of [ancestor], or
  /// null when the origin is not on screen.
  Rect? rectIn(RenderBox ancestor) {
    if (!mounted) return null;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return MatrixUtils.transformRect(
      box.getTransformTo(ancestor),
      Offset.zero & box.size,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Opens a floating glass sheet that grows out of the nearest
/// [GlassSheetOrigin] above [context].
///
/// The sheet ends where [GlassSheet] floats: [GlassSheet.sideMargin] from
/// the sides, [GlassSheet.bottomGapOf] from the bottom, with
/// [GlassSheet.cornerRadius] corners and opaque Liquid Glass. [builder]
/// returns the sheet content without a surface. The route paints the glass
/// and adds [padding] around the content.
///
/// Motion: a [Motion.springSettle] spring moves the bounds, the corners, and
/// the dimming from the exact bounds of the origin to the sheet. The glass
/// appears on the origin in the first 30 % of the transition and grows from
/// there, and the content fades in from 30 % to 85 %. The origin itself
/// stays in place, unchanged. The dimming covers the whole screen evenly.
/// Closing, from the close button, a tap outside, a downward drag, or the
/// back button, plays the same spring back into the bounds of the origin,
/// measured again at that moment. With reduced motion, the sheet opens and
/// closes at once.
///
/// Without an origin, the sheet grows up from the bottom edge.
Future<T?> showExpandingGlassSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  EdgeInsets padding = EdgeInsets.zero,
}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  final origin = GlassSheetOrigin.maybeOf(context);
  final overlay = navigator.overlay!.context.findRenderObject()! as RenderBox;

  final route = _ExpandingGlassSheetRoute<T>(
    builder: builder,
    padding: padding,
    origin: origin,
    originRect: origin?.rectIn(overlay),
    originRadius: origin?.widget.borderRadius ?? BorderRadius.zero,
    overlay: overlay,
    reduced: Motion.isReduced(context),
    dimColor:
        Theme.of(context).bottomSheetTheme.modalBarrierColor ?? Colors.black54,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  );
  return navigator.push(route);
}

class _ExpandingGlassSheetRoute<T> extends PopupRoute<T> {
  _ExpandingGlassSheetRoute({
    required this.builder,
    required this.padding,
    required this.origin,
    required this.originRect,
    required this.originRadius,
    required this.overlay,
    required this.reduced,
    required this.dimColor,
    required this.barrierLabel,
  });

  final WidgetBuilder builder;
  final EdgeInsets padding;
  final GlassSheetOriginState? origin;
  final BorderRadius originRadius;
  final RenderBox overlay;
  final bool reduced;

  /// Color of the dimming at full strength. The route paints the dimming
  /// itself, so that it also follows a downward drag.
  final Color dimColor;

  /// Bounds of the origin in the overlay. The route measures them again when
  /// it closes, in case the origin moved while the sheet was open.
  Rect? originRect;

  /// Returns the corners at progress [t], from the corners of the origin
  /// to the corners of [GlassSheet].
  ///
  /// The origin corners are first cut to half the shortest side of the
  /// origin: a capsule declares 999 pt corners but shows half its height.
  /// Starting from the declared value keeps the glass an oval for most of
  /// the transition and snaps the corners in at the end.
  BorderRadius radiusAt(double t) {
    final size = originRect?.size;
    final start = size == null ? originRadius : _fitRadius(originRadius, size);
    return BorderRadius.lerp(
      start,
      const BorderRadius.all(Radius.circular(GlassSheet.cornerRadius)),
      t.clamp(0.0, 1.0),
    )!;
  }

  @override
  final String barrierLabel;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration =>
      reduced ? Duration.zero : Motion.durationSlow;

  @override
  Duration get reverseTransitionDuration =>
      reduced ? Duration.zero : Motion.durationExit;

  @override
  Simulation? createSimulation({required bool forward}) {
    if (reduced) return null;
    return SpringSimulation(
      Motion.springSettle,
      controller!.value,
      forward ? 1 : 0,
      0,
      snapToEnd: true,
    );
  }

  @override
  bool didPop(T? result) {
    if (origin?.rectIn(overlay) case final rect?) originRect = rect;
    return super.didPop(result);
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _ExpandingSheetFrame(
      route: this,
      animation: animation,
      child: builder(context),
    );
  }
}

/// Cuts each corner of [radius] to half the shortest side of [size], the
/// largest corner that a box of [size] shows.
BorderRadius _fitRadius(BorderRadius radius, Size size) {
  final limit = size.shortestSide / 2;
  Radius fit(Radius r) =>
      Radius.elliptical(math.min(r.x, limit), math.min(r.y, limit));
  return BorderRadius.only(
    topLeft: fit(radius.topLeft),
    topRight: fit(radius.topRight),
    bottomLeft: fit(radius.bottomLeft),
    bottomRight: fit(radius.bottomRight),
  );
}

/// Layout slots of [_ExpandingSheetFrame].
enum _Slot { surface, content }

class _ExpandingSheetFrame extends StatefulWidget {
  const _ExpandingSheetFrame({
    required this.route,
    required this.animation,
    required this.child,
  });

  final _ExpandingGlassSheetRoute<dynamic> route;
  final Animation<double> animation;
  final Widget child;

  @override
  State<_ExpandingSheetFrame> createState() => _ExpandingSheetFrameState();
}

class _ExpandingSheetFrameState extends State<_ExpandingSheetFrame>
    with SingleTickerProviderStateMixin {
  /// Distance of a downward drag. It moves the sheet and fades the dimming.
  final ValueNotifier<double> _drag = ValueNotifier(0);

  /// Current bounds and corners of the glass, written by the layout.
  final ValueNotifier<_SheetGeometry> _geometry = ValueNotifier(
    const _SheetGeometry(Rect.zero, BorderRadius.zero, 1),
  );

  /// Settles a released drag back to 0.
  late final AnimationController _settle;

  /// Fade of the glass: it shows on the origin early, so the sheet reads as
  /// growing out of it.
  static const _glassFade = _Window(0, 0.3);

  /// Fade of the content: it arrives once the glass has grown.
  static const _contentFade = _Window(0.3, 0.85);

  /// A drag past this share of the sheet height closes the sheet.
  static const double _closeShare = 0.25;

  /// A downward fling faster than this closes the sheet, in pt per second.
  static const double _closeVelocity = 700;

  @override
  void initState() {
    super.initState();
    _settle = AnimationController.unbounded(vsync: this)
      ..addListener(() => _drag.value = math.max(0, _settle.value));
  }

  @override
  void dispose() {
    _settle.dispose();
    _drag.dispose();
    _geometry.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!widget.route.isCurrent) return;
    _settle.stop();
    _drag.value = math.max(0, _drag.value + details.primaryDelta!);
  }

  void _onDragEnd(DragEndDetails details) {
    if (!widget.route.isCurrent) return;
    final velocity = details.primaryVelocity ?? 0;
    final height = _geometry.value.sheetHeight;
    if (velocity > _closeVelocity || _drag.value > height * _closeShare) {
      Navigator.of(context).pop();
      return;
    }
    if (widget.route.reduced) {
      _drag.value = 0;
      return;
    }
    _settle.value = _drag.value;
    _settle.animateWith(
      SpringSimulation(Motion.springSettle, _drag.value, 0, velocity),
    );
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final animation = widget.animation;
    final padding = MediaQuery.paddingOf(context);
    final ticker = Listenable.merge([animation, _drag]);

    return Stack(
      fit: StackFit.expand,
      children: [
        // The dimming lets taps through to the route barrier, which closes
        // the sheet.
        IgnorePointer(
          child: AnimatedBuilder(
            animation: ticker,
            builder: (context, _) {
              final height = _geometry.value.sheetHeight;
              final release = height == 0
                  ? 1.0
                  : 1 - (_drag.value / height).clamp(0.0, 1.0);
              final strength = animation.value.clamp(0.0, 1.0) * release;
              return ColoredBox(
                color: route.dimColor.withValues(
                  alpha: route.dimColor.a * strength,
                ),
              );
            },
          ),
        ),
        CustomMultiChildLayout(
          delegate: _ExpandingSheetLayout(
            animation: animation,
            drag: _drag,
            geometry: _geometry,
            route: route,
            topInset: padding.top,
            bottomGap: GlassSheet.bottomGapOf(context),
          ),
          children: [
            LayoutId(
              id: _Slot.surface,
              child: FadeTransition(
                opacity: animation.drive(_glassFade),
                child: AnimatedBuilder(
                  animation: animation,
                  builder: (context, _) => LiquidGlass(
                    borderRadius: route.radiusAt(animation.value),
                    blurBackdrop: false,
                    opaque: true,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            LayoutId(
              id: _Slot.content,
              child: ClipPath(
                clipper: _SheetClipper(_geometry),
                child: FadeTransition(
                  opacity: animation.drive(_contentFade),
                  child: GestureDetector(
                    onVerticalDragUpdate: _onDragUpdate,
                    onVerticalDragEnd: _onDragEnd,
                    child: Material(
                      type: MaterialType.transparency,
                      child: Padding(
                        padding: route.padding,
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Bounds and corners of the glass at one moment of the transition.
@immutable
class _SheetGeometry {
  const _SheetGeometry(this.rect, this.radius, this.sheetHeight);

  final Rect rect;
  final BorderRadius radius;

  /// Height of the open sheet.
  final double sheetHeight;
}

/// Lays out the open sheet, then places the glass and the content between
/// the origin and the open sheet.
///
/// The content keeps the size of the open sheet for the whole transition,
/// so the chart and the text never reflow. [_SheetClipper] shows only the
/// part inside the glass.
class _ExpandingSheetLayout extends MultiChildLayoutDelegate {
  _ExpandingSheetLayout({
    required this.animation,
    required this.drag,
    required this.geometry,
    required this.route,
    required this.topInset,
    required this.bottomGap,
  }) : super(relayout: Listenable.merge([animation, drag]));

  final Animation<double> animation;
  final ValueNotifier<double> drag;
  final ValueNotifier<_SheetGeometry> geometry;
  final _ExpandingGlassSheetRoute<dynamic> route;
  final double topInset;
  final double bottomGap;

  /// Smallest space between the open sheet and the status bar.
  static const double _topGap = 8;

  @override
  void performLayout(Size size) {
    final width = size.width - GlassSheet.sideMargin * 2;
    final maxHeight = math.min(
      size.height * 0.9,
      size.height - topInset - _topGap - bottomGap,
    );
    final sheetSize = layoutChild(
      _Slot.content,
      BoxConstraints(minWidth: width, maxWidth: width, maxHeight: maxHeight),
    );
    final sheet = Rect.fromLTWH(
      GlassSheet.sideMargin,
      size.height - bottomGap - sheetSize.height + drag.value,
      width,
      sheetSize.height,
    );
    final origin =
        route.originRect ??
        Rect.fromLTWH(sheet.left, size.height, sheet.width, sheet.height / 4);

    final t = animation.value.clamp(0.0, 1.0);
    final rect = Rect.lerp(origin, sheet, t)!;
    final radius = route.radiusAt(t);
    geometry.value = _SheetGeometry(rect, radius, sheetSize.height);

    layoutChild(_Slot.surface, BoxConstraints.tight(rect.size));
    positionChild(_Slot.surface, rect.topLeft);
    positionChild(_Slot.content, rect.topLeft);
  }

  @override
  bool shouldRelayout(_ExpandingSheetLayout oldDelegate) =>
      oldDelegate.route != route ||
      oldDelegate.topInset != topInset ||
      oldDelegate.bottomGap != bottomGap;
}

/// Maps the transition progress to a value that moves from 0 to 1 between
/// [begin] and [end].
///
/// The progress is clamped first: a spring can end a hair outside 0..1.
class _Window extends Animatable<double> {
  const _Window(this.begin, this.end);

  final double begin;
  final double end;

  @override
  double transform(double t) =>
      Interval(begin, end).transform(t.clamp(0.0, 1.0));
}

/// Clips the content to the current glass bounds, in the coordinates of
/// the content.
class _SheetClipper extends CustomClipper<Path> {
  _SheetClipper(this.geometry) : super(reclip: geometry);

  final ValueNotifier<_SheetGeometry> geometry;

  @override
  Path getClip(Size size) {
    final value = geometry.value;
    return Path()
      ..addRRect(value.radius.toRRect(Offset.zero & value.rect.size));
  }

  @override
  bool shouldReclip(_SheetClipper oldClipper) =>
      oldClipper.geometry != geometry;
}
