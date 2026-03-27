import 'package:flutter/material.dart';

/// [ThemeExtension] for semantic color tokens not covered by Material's
/// [ColorScheme].
///
/// Covers app-specific roles that have no direct Material 3 equivalent:
/// warnings, extended text hierarchy, shimmer, navigation FAB, PIN surfaces,
/// custom card backgrounds, icon tints, and edit actions.
///
/// **Access in widgets:**
/// ```dart
/// // Preferred — via BuildContext extension (theme_context_x.dart):
/// final extra = context.appColors;
///
/// // Or directly:
/// final extra = Theme.of(context).extension<AppExtraColors>()!;
/// ```
@immutable
class AppExtraColors extends ThemeExtension<AppExtraColors> {
  // ── Warning ───────────────────────────────────────────────────────────────

  /// Background / border color for warning states.
  final Color warning;

  /// Foreground color for warning text and icons.
  final Color onWarning;

  // ── Extended text hierarchy ───────────────────────────────────────────────
  // Material's ColorScheme provides onSurface (primary text) and
  // onSurfaceVariant (secondary text). These slots cover the app's
  // finer-grained text tiers beyond those two roles.

  /// Muted text — labels, captions, secondary values.
  final Color textSecondary;

  /// Dimmer muted text — timestamps, hints, tertiary labels.
  final Color textTertiary;

  /// Extra-muted text used for placeholder / disabled content.
  final Color textQuartiary;

  /// Softest text tier — decorative or least-emphasis labels.
  final Color textQuintary;

  // ── Shimmer ───────────────────────────────────────────────────────────────

  /// Base color for shimmer skeleton animations.
  final Color shimmerBase;

  /// Highlight color that sweeps across shimmer skeletons.
  final Color shimmerHighlight;

  // ── Navigation ────────────────────────────────────────────────────────────

  /// Background of the floating action button on the bottom nav bar.
  final Color navBarFabBackground;

  // ── PIN surface ───────────────────────────────────────────────────────────

  /// Background of a focused / filled PIN input cell.
  final Color pinBackground;

  // ── Custom surfaces ───────────────────────────────────────────────────────

  /// Background of the recovery-phrase display card.
  final Color recoveryPhraseBackground;

  // ── Icons ─────────────────────────────────────────────────────────────────

  /// Tint applied to primary decorative icons (e.g. asset icons).
  final Color primaryIconColor;

  // ── Status / actions ──────────────────────────────────────────────────────

  /// Color indicating an editable / pending-edit state (e.g. edit mode badge).
  final Color editColor;

  // ── Buttons ───────────────────────────────────────────────────────────────

  /// Background for secondary action buttons (e.g. Send / Receive / Swap).
  final Color actionButtonBackground;

  // ── Constructor ───────────────────────────────────────────────────────────

  const AppExtraColors({
    required this.warning,
    required this.onWarning,
    required this.textSecondary,
    required this.textTertiary,
    required this.textQuartiary,
    required this.textQuintary,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.navBarFabBackground,
    required this.pinBackground,
    required this.recoveryPhraseBackground,
    required this.primaryIconColor,
    required this.editColor,
    required this.actionButtonBackground,
  });

  // ── Theme instances ───────────────────────────────────────────────────────

  /// Token values for the dark theme.
  static const dark = AppExtraColors(
    warning: Color(0xFFFB8C00),
    onWarning: Color(0xFFFFB74D),
    textSecondary: Color(0xFF9194A6),
    textTertiary: Color(0xFF7C7C7C),
    textQuartiary: Color(0xFFC2C2C2),
    textQuintary: Color(0xFFA6A0BB),
    shimmerBase: Color(0xFF757575),
    shimmerHighlight: Color(0xFFBDBDBD),
    navBarFabBackground: Color(0xFFAD1457),
    pinBackground: Color(0xFF191818),
    recoveryPhraseBackground: Color(0xFF1C1924),
    primaryIconColor: Color(0xFF9DB2CE),
    editColor: Colors.orangeAccent,
    actionButtonBackground: Color(0xFF2B2D33),
  );

  /// Token values for the light theme.
  static const light = AppExtraColors(
    warning: Color(0xFFE65100),
    onWarning: Color(0xFFF57C00),
    textSecondary: Color(0xFF5C5F72),
    textTertiary: Color(0xFF6B6B6B),
    textQuartiary: Color(0xFF8A8A8A),
    textQuintary: Color(0xFF7B7595),
    shimmerBase: Color(0xFFBDBDBD),
    shimmerHighlight: Color(0xFFE8E8E8),
    navBarFabBackground: Color(0xFFAD1457),
    pinBackground: Color(0xFFF5F5F5),
    recoveryPhraseBackground: Color(0xFFF0EEF5),
    primaryIconColor: Color(0xFF5B7A9A),
    editColor: Colors.orange,
    actionButtonBackground: Color(0xFFD1D5DB),
  );

  // ── ThemeExtension API ────────────────────────────────────────────────────

  @override
  AppExtraColors copyWith({
    Color? warning,
    Color? onWarning,
    Color? textSecondary,
    Color? textTertiary,
    Color? textQuartiary,
    Color? textQuintary,
    Color? shimmerBase,
    Color? shimmerHighlight,
    Color? navBarFabBackground,
    Color? pinBackground,
    Color? recoveryPhraseBackground,
    Color? primaryIconColor,
    Color? editColor,
    Color? actionButtonBackground,
  }) {
    return AppExtraColors(
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textQuartiary: textQuartiary ?? this.textQuartiary,
      textQuintary: textQuintary ?? this.textQuintary,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
      navBarFabBackground: navBarFabBackground ?? this.navBarFabBackground,
      pinBackground: pinBackground ?? this.pinBackground,
      recoveryPhraseBackground:
          recoveryPhraseBackground ?? this.recoveryPhraseBackground,
      primaryIconColor: primaryIconColor ?? this.primaryIconColor,
      editColor: editColor ?? this.editColor,
      actionButtonBackground:
          actionButtonBackground ?? this.actionButtonBackground,
    );
  }

  @override
  AppExtraColors lerp(AppExtraColors? other, double t) {
    if (other is! AppExtraColors) return this;
    return AppExtraColors(
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textQuartiary: Color.lerp(textQuartiary, other.textQuartiary, t)!,
      textQuintary: Color.lerp(textQuintary, other.textQuintary, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight:
          Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
      navBarFabBackground:
          Color.lerp(navBarFabBackground, other.navBarFabBackground, t)!,
      pinBackground: Color.lerp(pinBackground, other.pinBackground, t)!,
      recoveryPhraseBackground:
          Color.lerp(
            recoveryPhraseBackground,
            other.recoveryPhraseBackground,
            t,
          )!,
      primaryIconColor:
          Color.lerp(primaryIconColor, other.primaryIconColor, t)!,
      editColor: Color.lerp(editColor, other.editColor, t)!,
      actionButtonBackground:
          Color.lerp(actionButtonBackground, other.actionButtonBackground, t)!,
    );
  }
}
