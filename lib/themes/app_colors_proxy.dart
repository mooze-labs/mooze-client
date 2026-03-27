import 'package:flutter/material.dart';
import 'app_extra_colors.dart';

/// A unified, theme-aware façade over [ColorScheme] and [AppExtraColors].
///
/// Exposes every property that the old `AppColors` static class had, but
/// resolved against the active theme at runtime. This makes incremental
/// migration trivial: widgets simply replace `AppColors.foo` with
/// `context.colors.foo` — the property names are identical.
///
/// Obtain an instance via the [BuildContext.colors] extension:
/// ```dart
/// import 'package:mooze_mobile/themes/theme_context_x.dart';
///
/// final bg = context.colors.backgroundColor;
/// final primary = context.colors.primaryColor;
/// ```
///
/// The proxy is intentionally thin — it delegates to [ColorScheme] for
/// standard Material 3 roles and to [AppExtraColors] for custom tokens.
/// No color values are hardcoded here.
@immutable
class AppColorsProxy {
  final ColorScheme _cs;
  final AppExtraColors _extra;

  const AppColorsProxy(this._cs, this._extra);

  // ── Primary ───────────────────────────────────────────────────────────────

  Color get primaryColor => _cs.primary;

  /// [pinkAccent] semantically equals primary in this design system.
  Color get pinkAccent => _cs.primary;

  Color get onPrimaryColor => _cs.onPrimary;

  // ── Backgrounds ───────────────────────────────────────────────────────────

  /// The darkest background level — maps to [ColorScheme.surfaceDim].
  Color get backgroundColor => _cs.surfaceDim;

  /// Card surface — maps to [ColorScheme.surfaceContainerLowest].
  Color get backgroundCard => _cs.surfaceContainerLowest;

  /// Pure overlay scrim — maps to [ColorScheme.scrim].
  Color get absoluteBlack => _cs.scrim;

  // ── Text ──────────────────────────────────────────────────────────────────

  /// Primary text — maps to [ColorScheme.onSurface].
  Color get textPrimary => _cs.onSurface;

  /// Muted secondary text — from [AppExtraColors.textSecondary].
  Color get textSecondary => _extra.textSecondary;

  /// Tertiary text (timestamps, hints) — from [AppExtraColors.textTertiary].
  Color get textTertiary => _extra.textTertiary;

  /// Quartiary text — from [AppExtraColors.textQuartiary].
  Color get textQuartiary => _extra.textQuartiary;

  /// Quintary text — from [AppExtraColors.textQuintary].
  Color get textQuintary => _extra.textQuintary;

  /// 60 % opacity text — onSurface at 60 % alpha for readability in both themes.
  Color get textWhite60 => _cs.onSurface.withValues(alpha: 0.6);

  // ── Status ────────────────────────────────────────────────────────────────

  /// Positive / success — maps to [ColorScheme.tertiary].
  Color get positiveColor => _cs.tertiary;

  /// Negative / destructive — maps to [ColorScheme.error].
  Color get negativeColor => _cs.error;

  /// Error — maps to [ColorScheme.error].
  Color get errorColor => _cs.error;

  /// Edit / pending state indicator — from [AppExtraColors.editColor].
  Color get editColor => _extra.editColor;

  // ── Surface ───────────────────────────────────────────────────────────────

  /// Default surface — maps to [ColorScheme.surface].
  Color get surfaceColor => _cs.surface;

  /// Swap card surface — maps to [ColorScheme.surfaceContainer].
  Color get swapCardBackground => _cs.surfaceContainer;

  /// Border / divider — maps to [ColorScheme.outline].
  Color get swapLinearBorder => _cs.outline;

  /// Recovery-phrase card — from [AppExtraColors.recoveryPhraseBackground].
  Color get recoveryPhraseBackground => _extra.recoveryPhraseBackground;

  /// Low-elevation surface — maps to [ColorScheme.surfaceContainerLow].
  Color get surfaceLow => _cs.surfaceContainerLow;

  // ── Secondary ─────────────────────────────────────────────────────────────

  /// Secondary container — maps to [ColorScheme.secondary].
  Color get secondaryColor => _cs.secondary;

  /// Grey shade 500 equivalent — maps to [AppExtraColors.textTertiary].
  Color get greyShade500 => _extra.textTertiary;

  // ── PIN ───────────────────────────────────────────────────────────────────

  /// PIN cell background — from [AppExtraColors.pinBackground].
  Color get pinBackground => _extra.pinBackground;

  // ── Logo ──────────────────────────────────────────────────────────────────

  /// App logo tint — [ColorScheme.primary] in light mode,
  /// [ColorScheme.onPrimary] in dark mode.
  Color get logoColor =>
      _cs.brightness == Brightness.light ? _cs.primary : _cs.onPrimary;

  // ── Icon ──────────────────────────────────────────────────────────────────

  /// Primary icon tint — from [AppExtraColors.primaryIconColor].
  Color get primaryIconColor => _extra.primaryIconColor;

  // ── NavBar ────────────────────────────────────────────────────────────────

  /// Nav bar background — maps to [ColorScheme.surface].
  Color get navBarBackground => _cs.surface;

  /// Nav bar FAB background — from [AppExtraColors.navBarFabBackground].
  Color get navBarFabBackground => _extra.navBarFabBackground;

  // ── Buttons ───────────────────────────────────────────────────────────────

  /// Background for secondary action buttons — from [AppExtraColors.actionButtonBackground].
  Color get actionButtonBackground => _extra.actionButtonBackground;

  // ── Shimmer ───────────────────────────────────────────────────────────────

  /// Shimmer base (dark skeleton) — from [AppExtraColors.shimmerBase].
  Color get baseColor => _extra.shimmerBase;

  /// Shimmer highlight (sweep color) — from [AppExtraColors.shimmerHighlight].
  Color get highlightColor => _extra.shimmerHighlight;
}
