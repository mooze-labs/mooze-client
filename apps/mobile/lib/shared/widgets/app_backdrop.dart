import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Paints the backdrop of the main screens (see [BackdropStyle]).
///
/// Put one [AppBackdrop] behind the screen content with [origin] 0. A pinned
/// header or an app bar that must hide the content below it paints its own
/// [AppBackdrop] with its distance from the top of the screen as [origin].
/// The two then match without a seam.
class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key, this.origin = 0});

  /// Distance from the top of the screen to the top of this widget.
  final double origin;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _BackdropPainter(BackdropStyle.of(context), origin),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter(this.style, this.origin);

  final BackdropStyle style;
  final double origin;

  @override
  void paint(Canvas canvas, Size size) {
    final area = Offset.zero & size;
    canvas.drawRect(area, Paint()..color = style.base);

    // The gradient box starts at the top of the screen, not of this widget.
    final box = Rect.fromLTWH(0, -origin, size.width, style.extent);
    final gradientArea = area.intersect(box);
    if (!gradientArea.isEmpty) {
      canvas.drawRect(
        gradientArea,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: style.colors,
            stops: style.stops,
          ).createShader(box),
      );
    }

    final glow = style.glow;
    if (glow != null) {
      canvas.drawRect(
        area,
        Paint()
          ..shader = RadialGradient(
            center: style.glowCenter,
            radius: style.glowRadius,
            colors: [glow, glow.withValues(alpha: 0)],
          ).createShader(box),
      );
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) =>
      oldDelegate.origin != origin ||
      oldDelegate.style.base != style.base ||
      oldDelegate.style.glow != style.glow ||
      oldDelegate.style.extent != style.extent ||
      !_sameColors(oldDelegate.style.colors, style.colors);

  static bool _sameColors(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// An app bar that shows the backdrop behind its title.
///
/// The bar paints its slice of the backdrop, so it looks transparent and
/// still hides the content that scrolls under it. Use it with
/// `Scaffold(extendBodyBehindAppBar: true)` and an [AppBackdrop] behind the
/// body.
class BackdropAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BackdropAppBar({super.key, this.title, this.actions});

  final Widget? title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      actions: actions,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: context.colors.textPrimary,
      // The bar starts at the top of the screen, so its slice has origin 0.
      flexibleSpace: const AppBackdrop(),
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
