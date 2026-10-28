import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// Surface recipes shared by the main screens.
///
/// Dark surfaces rise by one tone step and carry a faint rim. Light surfaces
/// are white with a soft shadow. Both recipes read from the active theme, so
/// widgets never write raw colors.
abstract final class AppSurfaces {
  /// Corner radius of grouped panels.
  static const BorderRadius panelRadius = BorderRadius.all(Radius.circular(20));

  /// Grouped panel for lists and settings groups.
  static BoxDecoration panel(
    BuildContext context, {
    BorderRadius radius = panelRadius,
  }) {
    final colorScheme = context.colorScheme;
    if (_isDark(context)) {
      return BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: radius,
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      );
    }
    return BoxDecoration(
      color: colorScheme.surfaceContainerLowest,
      borderRadius: radius,
      boxShadow: _softShadow(colorScheme),
    );
  }

  /// Raised control, for example a circle action button.
  ///
  /// In light mode the control is white, so a rim and a shadow separate it
  /// from the light top of the backdrop.
  static BoxDecoration raised(
    BuildContext context, {
    BoxShape shape = BoxShape.circle,
  }) {
    final colorScheme = context.colorScheme;
    if (_isDark(context)) {
      return BoxDecoration(
        color: context.colors.actionButtonBackground,
        shape: shape,
      );
    }
    return BoxDecoration(
      color: colorScheme.surfaceContainerLowest,
      shape: shape,
      border: Border.all(color: colorScheme.outlineVariant),
      boxShadow: _softShadow(colorScheme),
    );
  }

  /// Hairline between rows inside a panel.
  static Color hairline(BuildContext context) => _isDark(context)
      ? context.colorScheme.onSurface.withValues(alpha: 0.08)
      : context.colorScheme.outlineVariant;

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static List<BoxShadow> _softShadow(ColorScheme colorScheme) => [
    BoxShadow(
      color: colorScheme.shadow.withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: colorScheme.shadow.withValues(alpha: 0.03),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ];
}

/// The light at the top of the main screens.
///
/// The backdrop is defined from the top edge of the screen. A widget below
/// the top edge, for example a pinned header, paints its slice of the same
/// backdrop with an origin, so both parts match without a visible seam.
@immutable
class BackdropStyle {
  const BackdropStyle({
    required this.colors,
    required this.stops,
    required this.extent,
    required this.base,
    this.glow,
    this.glowCenter = Alignment.topRight,
    this.glowRadius = 1,
  });

  /// Top-to-bottom gradient colors over [extent].
  final List<Color> colors;
  final List<double> stops;

  /// Height of the gradient from the top of the screen.
  final double extent;

  /// Page color below the gradient.
  final Color base;

  /// Optional soft radial light. Null means no radial light.
  final Color? glow;

  /// Center of [glow] in the box of width × [extent].
  final Alignment glowCenter;

  /// Radius of [glow], as a fraction of the shorter side of that box.
  final double glowRadius;

  /// Returns the backdrop of the active theme.
  ///
  /// Dark: a graphite light that fades into the black page ("homeTopGlow").
  /// Light: a pearl wash from white to the page gray, with a faint brand
  /// blush in the top right corner. It keeps the same idea, a soft light
  /// from the top, with colors made for a light page.
  static BackdropStyle of(BuildContext context) {
    final colorScheme = context.colorScheme;
    if (Theme.of(context).brightness == Brightness.dark) {
      return BackdropStyle(
        colors: [colorScheme.surfaceContainerHighest, colorScheme.surfaceDim],
        stops: const [0, 1],
        extent: 360,
        base: colorScheme.surfaceDim,
      );
    }
    return BackdropStyle(
      colors: [
        colorScheme.surfaceBright,
        colorScheme.surface,
        colorScheme.surfaceDim,
      ],
      stops: const [0, 0.45, 1],
      extent: 460,
      base: colorScheme.surfaceDim,
      glow: colorScheme.primaryContainer.withValues(alpha: 0.55),
      glowCenter: const Alignment(0.95, -1.1),
      glowRadius: 0.85,
    );
  }
}

/// The recipe of a Liquid Glass surface, for example the floating
/// navigation capsule.
///
/// The glass blurs and saturates the content behind it, tints it, and adds
/// a specular sheen, a gradient rim, and a soft refraction glow inside the
/// edge. Dark glass is a smoked graphite with luminous edges. Light glass is
/// a bright frosted white with a crisp rim and a softer shadow.
@immutable
class GlassStyle {
  const GlassStyle({
    required this.blurSigma,
    required this.saturation,
    required this.tints,
    required this.sheen,
    required this.rim,
    required this.edgeGlow,
    required this.shadows,
    required this.lensFill,
    required this.lensRim,
    required this.lensShadows,
  });

  /// Blur of the content behind the glass.
  final double blurSigma;

  /// Saturation of the blurred content. 1 keeps the colors.
  final double saturation;

  /// Fills painted over the blurred content, bottom first.
  final List<Color> tints;

  /// Diagonal light over the glass, from the top left corner.
  final List<Color> sheen;

  /// Rim colors from the top edge to the bottom edge.
  final List<Color> rim;

  /// Soft light just inside the edge, like light bent by a thick glass.
  final Color edgeGlow;

  final List<BoxShadow> shadows;

  /// Fill of the selected-item lens inside the glass.
  final Color lensFill;

  /// Rim colors of the lens, from top to bottom.
  final List<Color> lensRim;

  final List<BoxShadow> lensShadows;

  /// Returns the glass of the active theme.
  static GlassStyle of(BuildContext context) {
    final colorScheme = context.colorScheme;
    if (Theme.of(context).brightness == Brightness.dark) {
      const white = Colors.white;
      return GlassStyle(
        blurSigma: 18,
        saturation: 1.8,
        // A dark smoke keeps the icons readable over bright content. A
        // faint white lift makes the surface read as glass, not as a hole.
        tints: [
          colorScheme.surfaceDim.withValues(alpha: 0.5),
          white.withValues(alpha: 0.05),
        ],
        sheen: [
          white.withValues(alpha: 0.14),
          white.withValues(alpha: 0),
          white.withValues(alpha: 0.04),
        ],
        rim: [white.withValues(alpha: 0.30), white.withValues(alpha: 0.06)],
        edgeGlow: white.withValues(alpha: 0.07),
        shadows: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.45),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        lensFill: white.withValues(alpha: 0.11),
        lensRim: [white.withValues(alpha: 0.28), white.withValues(alpha: 0.06)],
        lensShadows: const [],
      );
    }
    const white = Colors.white;
    return GlassStyle(
      blurSigma: 18,
      saturation: 1.6,
      // A bright frost keeps the icons readable over dark content.
      tints: [
        white.withValues(alpha: 0.72),
        colorScheme.primaryContainer.withValues(alpha: 0.06),
      ],
      sheen: [
        white.withValues(alpha: 0.65),
        white.withValues(alpha: 0),
        white.withValues(alpha: 0.30),
      ],
      rim: [white, colorScheme.outlineVariant],
      edgeGlow: white.withValues(alpha: 0.55),
      shadows: [
        BoxShadow(
          color: colorScheme.shadow.withValues(alpha: 0.10),
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: colorScheme.shadow.withValues(alpha: 0.05),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
      lensFill: white.withValues(alpha: 0.92),
      lensRim: [white, colorScheme.outlineVariant],
      lensShadows: [
        BoxShadow(
          color: colorScheme.shadow.withValues(alpha: 0.08),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}
