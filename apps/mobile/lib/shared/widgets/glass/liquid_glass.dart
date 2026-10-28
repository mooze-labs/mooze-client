import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';

/// A Liquid Glass surface in the shape of a rounded rectangle or a capsule.
///
/// Layers, from the back:
/// 1. A floating shadow outside the shape.
/// 2. The content behind the glass, blurred and saturated.
/// 3. Tints that keep the foreground readable.
/// 4. A diagonal sheen and a soft glow just inside the edge.
/// 5. [child].
/// 6. A gradient rim, bright at the top and faint at the bottom.
///
/// With [blurBackdrop], the surface uses one backdrop filter. Use it only
/// where content moves behind the glass, for example under a floating bar:
/// the blur reads the screen behind it on every frame. A card in scrolling
/// content sits on the fixed screen backdrop, so it sets [blurBackdrop] to
/// false: it keeps every other layer and costs no blur.
///
/// An overlay, for example a sheet or a dialog, covers busy content. It sets
/// [opaque], so the content behind it does not show through.
class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(999)),
    this.blurBackdrop = true,
    this.opaque = false,
  });

  final Widget child;
  final BorderRadius borderRadius;

  /// Blurs and saturates the content behind the glass.
  final bool blurBackdrop;

  /// Paints the page color under the tints. The glass then has the same
  /// tone as a glass card on the screen backdrop, and hides what is behind
  /// it.
  final bool opaque;

  /// Returns the luminance-preserving saturation matrix for [saturation].
  static List<double> saturationMatrix(double saturation) {
    final s = saturation;
    const r = 0.2126, g = 0.7152, b = 0.0722;
    return [
      r + (1 - r) * s, g - g * s, b - b * s, 0, 0, //
      r - r * s, g + (1 - g) * s, b - b * s, 0, 0, //
      r - r * s, g - g * s, b + (1 - b) * s, 0, 0, //
      0, 0, 0, 1, 0, //
    ];
  }

  @override
  Widget build(BuildContext context) {
    final glass = GlassStyle.of(context);
    final body = CustomPaint(
      painter: _GlassBodyPainter(
        glass,
        borderRadius,
        base: opaque ? BackdropStyle.of(context).base : null,
      ),
      foregroundPainter: _GlassRimPainter(glass.rim, borderRadius),
      // Content updates (for example a new price) repaint only the content,
      // not the glass layers.
      child: RepaintBoundary(child: child),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: glass.shadows,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: blurBackdrop
            ? BackdropFilter(
                // Blur first, then lift the saturation of the blurred
                // colors, as light does through thick glass.
                filter: ui.ImageFilter.compose(
                  outer: ui.ColorFilter.matrix(
                    saturationMatrix(glass.saturation),
                  ),
                  inner: ui.ImageFilter.blur(
                    sigmaX: glass.blurSigma,
                    sigmaY: glass.blurSigma,
                    tileMode: TileMode.mirror,
                  ),
                ),
                child: body,
              )
            : body,
      ),
    );
  }
}

/// A grouped panel made of Liquid Glass, for a card in scrolling content.
///
/// It has the layers of [LiquidGlass] without the backdrop blur (see
/// [LiquidGlass.blurBackdrop]). Like `AppPanel`, it clips its content to
/// its corners and gives ink ripples a surface, so rows inside it can use
/// [InkWell].
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = AppSurfaces.panelRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  /// Returns the base color of the glass panel around [context]. Returns
  /// null outside a glass panel.
  ///
  /// The color is the glass tints over the page color, without the sheen.
  /// Use it where a widget cuts its outline out of the panel, for example
  /// the ring of a badge.
  static Color? maybeToneOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_GlassPanelScope>();
    if (scope == null) return null;
    return GlassStyle.of(context).tints.fold<Color>(
      BackdropStyle.of(context).base,
      (color, tint) => Color.alphaBlend(tint, color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      borderRadius: borderRadius,
      blurBackdrop: false,
      child: Material(
        type: MaterialType.transparency,
        child: _GlassPanelScope(
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// A floating modal bottom sheet made of opaque Liquid Glass.
///
/// Put it in the builder of `showModalBottomSheet` with a transparent
/// background color. The sheet does not touch the sides or the bottom of
/// the screen, and all its corners are round, like the floating navigation
/// bar. It has no backdrop blur (see [LiquidGlass.opaque]).
class GlassSheet extends StatelessWidget {
  const GlassSheet({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.constraints,
  });

  /// Space between the sheet and the sides of the screen.
  static const double sideMargin = 12;

  /// Smallest space between the sheet and the bottom of the screen.
  static const double minBottomGap = 12;

  /// Radius of the four corners.
  static const double cornerRadius = 40;

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Size limits of the glass, without the margins.
  final BoxConstraints? constraints;

  /// Returns the space between the sheet and the bottom of the screen.
  ///
  /// As for the floating navigation bar, the sheet sits just above the home
  /// indicator. Where the system has no bottom inset, it keeps
  /// [minBottomGap].
  static double bottomGapOf(BuildContext context) =>
      math.max(MediaQuery.paddingOf(context).bottom - 8, minBottomGap);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        sideMargin,
        0,
        sideMargin,
        bottomGapOf(context),
      ),
      child: ConstrainedBox(
        constraints: constraints ?? const BoxConstraints(),
        child: LiquidGlass(
          borderRadius: const BorderRadius.all(Radius.circular(cornerRadius)),
          blurBackdrop: false,
          opaque: true,
          child: Material(
            type: MaterialType.transparency,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// A dialog made of opaque Liquid Glass.
///
/// It keeps the size, the position, and the barrier of a [Dialog]. Only the
/// surface changes.
class GlassDialog extends StatelessWidget {
  const GlassDialog({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.semanticsRole = ui.SemanticsRole.dialog,
  });

  final Widget child;
  final BorderRadius borderRadius;

  /// Semantics role of the dialog. An alert uses [ui.SemanticsRole.alertDialog].
  final ui.SemanticsRole semanticsRole;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      semanticsRole: semanticsRole,
      child: LiquidGlass(
        borderRadius: borderRadius,
        blurBackdrop: false,
        opaque: true,
        child: Material(type: MaterialType.transparency, child: child),
      ),
    );
  }
}

/// An alert dialog made of opaque Liquid Glass.
///
/// It takes the title, the content, and the actions of an [AlertDialog]. It
/// lays them out with the Material 3 values of [AlertDialog]: 24 pt padding,
/// 16 pt between the title and the content, less padding with large text,
/// and the same semantics.
class GlassAlertDialog extends StatelessWidget {
  const GlassAlertDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.semanticLabel,
  });

  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final BorderRadius borderRadius;

  /// Label of the dialog for screen readers. Null uses the platform default,
  /// as [AlertDialog] does.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dialogTheme = DialogTheme.of(context);
    final title = this.title;
    final content = this.content;
    final actions = this.actions;
    final label = switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => semanticLabel,
      _ => semanticLabel ?? MaterialLocalizations.of(context).alertDialogLabel,
    };
    // Large text shrinks the outer padding: 1× at 100% text, 1/3 at 200%.
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final scale = ui.lerpDouble(1, 1 / 3, textScale.clamp(1.0, 2.0) - 1)!;

    Widget dialogChild = IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                24 * scale,
                24 * scale,
                24 * scale,
                content == null ? 20 : 0,
              ),
              child: DefaultTextStyle(
                style:
                    dialogTheme.titleTextStyle ??
                    theme.textTheme.headlineSmall!,
                child: Semantics(
                  // On iOS the focus lands on the title, so the title does
                  // not name the route a second time.
                  namesRoute:
                      label == null &&
                      defaultTargetPlatform != TargetPlatform.iOS,
                  container: true,
                  child: title,
                ),
              ),
            ),
          if (content != null)
            Flexible(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24 * scale,
                  title == null ? 16 * scale : 16,
                  24 * scale,
                  24,
                ),
                child: DefaultTextStyle(
                  style:
                      dialogTheme.contentTextStyle ??
                      theme.textTheme.bodyMedium!,
                  child: Semantics(
                    container: true,
                    explicitChildNodes: true,
                    child: content,
                  ),
                ),
              ),
            ),
          if (actions != null)
            Padding(
              padding:
                  dialogTheme.actionsPadding ??
                  const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: OverflowBar(
                alignment: MainAxisAlignment.end,
                spacing: 8,
                overflowAlignment: OverflowBarAlignment.end,
                children: actions,
              ),
            ),
        ],
      ),
    );
    if (label != null) {
      dialogChild = Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        namesRoute: true,
        label: label,
        child: dialogChild,
      );
    }
    return GlassDialog(
      borderRadius: borderRadius,
      semanticsRole: ui.SemanticsRole.alertDialog,
      child: dialogChild,
    );
  }
}

/// Marks the content of a [GlassPanel] for [GlassPanel.maybeToneOf].
class _GlassPanelScope extends InheritedWidget {
  const _GlassPanelScope({required super.child});

  @override
  bool updateShouldNotify(_GlassPanelScope oldWidget) => false;
}

/// A glass lens inside a [LiquidGlass] surface, for example the indicator
/// of the selected item.
class GlassLens extends StatelessWidget {
  const GlassLens({
    super.key,
    this.borderRadius = const BorderRadius.all(Radius.circular(999)),
  });

  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final glass = GlassStyle.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: glass.lensFill,
        borderRadius: borderRadius,
        boxShadow: glass.lensShadows,
      ),
      child: CustomPaint(
        foregroundPainter: _GlassRimPainter(glass.lensRim, borderRadius),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _GlassBodyPainter extends CustomPainter {
  _GlassBodyPainter(this.glass, this.borderRadius, {this.base});

  final GlassStyle glass;
  final BorderRadius borderRadius;

  /// Opaque color under the tints. Null keeps the glass translucent.
  final Color? base;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = borderRadius.toRRect(rect);

    if (base case final base?) {
      canvas.drawRRect(shape, Paint()..color = base);
    }
    for (final tint in glass.tints) {
      canvas.drawRRect(shape, Paint()..color = tint);
    }

    canvas.drawRRect(
      shape,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: glass.sheen,
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );

    // Light bent at the edge of a thick glass: a soft band just inside the
    // rim, stronger at the top.
    canvas.drawRRect(
      shape.deflate(3),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [glass.edgeGlow, glass.edgeGlow.withValues(alpha: 0)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_GlassBodyPainter oldDelegate) =>
      oldDelegate.glass != glass ||
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.base != base;
}

class _GlassRimPainter extends CustomPainter {
  _GlassRimPainter(this.colors, this.borderRadius);

  final List<Color> colors;
  final BorderRadius borderRadius;

  static const double _width = 1;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // The stroke sits fully inside the shape, so the clip keeps it whole.
    final shape = borderRadius.toRRect(rect).deflate(_width / 2);
    canvas.drawRRect(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _width
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_GlassRimPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
      !_sameColors(oldDelegate.colors, colors);

  static bool _sameColors(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
