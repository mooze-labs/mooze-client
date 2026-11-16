import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Paints the backdrop of the main screens (see [BackdropStyle]).
///
/// Put one [AppBackdrop] behind the screen content with [origin] 0. A pinned
/// header or an app bar that must hide the content below it paints its own
/// [AppBackdrop] with its distance from the top of the screen as [origin].
/// The two then match without a seam.
///
/// Inside a horizontal pager, such as the swipeable main screens, the glow
/// is placed on the pager, not on the page. During a swipe the glow then
/// stays in the corner of the screen, and two pages side by side read as one
/// backdrop instead of two glows cut at the page edge.
class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key, this.origin = 0});

  /// Distance from the top of the screen to the top of this widget.
  final double origin;

  @override
  Widget build(BuildContext context) {
    final style = BackdropStyle.of(context);
    return IgnorePointer(
      child: _BackdropBox(
        style: style,
        origin: origin,
        // Only the glow changes across the width. A backdrop without it,
        // like the dark one, is the same on every page and needs no pager.
        pager: style.glow == null
            ? null
            : Scrollable.maybeOf(context, axis: Axis.horizontal),
      ),
    );
  }
}

class _BackdropBox extends LeafRenderObjectWidget {
  const _BackdropBox({required this.style, required this.origin, this.pager});

  final BackdropStyle style;
  final double origin;
  final ScrollableState? pager;

  @override
  _RenderBackdrop createRenderObject(BuildContext context) =>
      _RenderBackdrop(style: style, origin: origin, pager: pager);

  @override
  void updateRenderObject(BuildContext context, _RenderBackdrop renderObject) {
    renderObject
      ..style = style
      ..origin = origin
      ..pager = pager;
  }
}

/// Fills its box with the backdrop, in its own layer.
class _RenderBackdrop extends RenderBox {
  _RenderBackdrop({
    required BackdropStyle style,
    required double origin,
    ScrollableState? pager,
  }) : _style = style,
       _origin = origin,
       _pager = pager;

  BackdropStyle _style;
  set style(BackdropStyle value) {
    if (_samePaint(_style, value)) return;
    _style = value;
    markNeedsPaint();
  }

  double _origin;
  set origin(double value) {
    if (_origin == value) return;
    _origin = value;
    markNeedsPaint();
  }

  ScrollableState? _pager;
  set pager(ScrollableState? value) {
    _pager = value;
    if (attached) _listenToPager();
  }

  /// The position this box listens to. A pager can swap its position, so
  /// the box keeps the one it subscribed to.
  ScrollPosition? _position;

  void _listenToPager() {
    final position = _pager?.position;
    if (position == _position) return;
    _position?.removeListener(markNeedsPaint);
    _position = position?..addListener(markNeedsPaint);
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _listenToPager();
  }

  @override
  void detach() {
    _position?.removeListener(markNeedsPaint);
    _position = null;
    super.detach();
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final area = offset & size;
    canvas.drawRect(area, Paint()..color = _style.base);

    // The wash starts at the top of the screen, not of this widget.
    final wash = Rect.fromLTWH(
      area.left,
      area.top - _origin,
      size.width,
      _style.extent,
    );
    final washArea = area.intersect(wash);
    if (!washArea.isEmpty) {
      canvas.drawRect(
        washArea,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _style.colors,
            stops: _style.stops,
          ).createShader(wash),
      );
    }

    final glow = _style.glow;
    if (glow != null) {
      canvas.drawRect(
        area,
        Paint()
          ..shader = RadialGradient(
            center: _style.glowCenter,
            radius: _style.glowRadius,
            colors: [glow, glow.withValues(alpha: 0)],
          ).createShader(_glowBox(wash)),
      );
    }
  }

  /// The box of the glow: the [wash] box, moved onto the pager if any.
  Rect _glowBox(Rect wash) {
    final pagerBox = _pager?.context.findRenderObject();
    if (pagerBox is! RenderBox || !pagerBox.hasSize) return wash;
    // Where this widget sits in the pager. A page swiped halfway out sits
    // half a page to the left or right.
    final inPager = localToGlobal(Offset.zero, ancestor: pagerBox).dx;
    return Rect.fromLTWH(
      wash.left - inPager,
      wash.top,
      pagerBox.size.width,
      wash.height,
    );
  }

  static bool _samePaint(BackdropStyle a, BackdropStyle b) =>
      a.base == b.base &&
      a.glow == b.glow &&
      a.glowCenter == b.glowCenter &&
      a.glowRadius == b.glowRadius &&
      a.extent == b.extent &&
      listEquals(a.colors, b.colors) &&
      listEquals(a.stops, b.stops);
}

/// An app bar that shows the backdrop behind its title.
///
/// The bar paints its slice of the backdrop, so it looks transparent and
/// still hides the content that scrolls under it. Use it with
/// `Scaffold(extendBodyBehindAppBar: true)` and an [AppBackdrop] behind the
/// body.
class BackdropAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BackdropAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.showsBackdrop = true,
  });

  /// Whether the bar paints its slice of the backdrop. A screen whose art
  /// reaches the top of the screen turns it off while nothing scrolls under
  /// the bar, so only the buttons of the bar cover the art. The slice fades
  /// in and out.
  final bool showsBackdrop;

  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: context.colors.textPrimary,
      // The bar starts at the top of the screen, so its slice has origin 0.
      flexibleSpace: AnimatedOpacity(
        opacity: showsBackdrop ? 1 : 0,
        duration: Motion.of(context, Motion.durationFast),
        curve: Motion.curveMove,
        child: const AppBackdrop(),
      ),
    );
  }
}

/// A grouped panel (see [AppSurfaces.panel]).
///
/// The panel clips its content to its corners and gives ink ripples a
/// surface, so rows inside it can use [InkWell].
class AppPanel extends StatelessWidget {
  const AppPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(vertical: 4),
    this.radius = AppSurfaces.panelRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppSurfaces.panel(context, radius: radius),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          type: MaterialType.transparency,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// A hairline between rows inside an [AppPanel].
///
/// [indent] lines it up with the row text.
class PanelDivider extends StatelessWidget {
  const PanelDivider({super.key, this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: indent,
      color: AppSurfaces.hairline(context),
    );
  }
}
