import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';

/// The colors of a celebration stage in the theme of a context: the page,
/// the metal of the token, its shadows, and its glint.
///
/// The dark stage is black, with a token of dark metal, and its effects
/// shine: their highlights are light. The light stage is a pearl page, with
/// a token of light metal, and its effects are colored: their highlights
/// take the tint, which shows on a light page where white would not.
@immutable
class StagePalette {
  const StagePalette({
    required this.isDark,
    required this.page,
    required this.base,
    required this.shade,
    required this.glint,
  });

  factory StagePalette.of(BuildContext context) {
    final colorScheme = context.colorScheme;
    if (Theme.of(context).brightness == Brightness.dark) {
      final black = context.colors.absoluteBlack;
      return StagePalette(
        isDark: true,
        page: black,
        base: black,
        shade: black.withValues(alpha: 0.7),
        glint: context.colors.textPrimary,
      );
    }
    return StagePalette(
      isDark: false,
      page: colorScheme.surface,
      base: colorScheme.surfaceBright,
      shade: colorScheme.shadow.withValues(alpha: 0.18),
      glint: colorScheme.surfaceBright,
    );
  }

  final bool isDark;

  /// The page behind the stage.
  final Color page;

  /// The metal of the token: the body of its face and its edge.
  final Color base;

  /// The shadows on the token: the emboss of its symbol and its bevel.
  final Color shade;

  /// The glint on the rim of the token.
  final Color glint;

  /// The highlights of the effects around a token in [tint]: the core of
  /// the flash, the bright particles, the sparkles, and the heads of the
  /// rings.
  Color highlight(Color tint) => isDark ? glint : tint;

  @override
  bool operator ==(Object other) =>
      other is StagePalette &&
      other.isDark == isDark &&
      other.page == page &&
      other.base == base &&
      other.shade == shade &&
      other.glint == glint;

  @override
  int get hashCode => Object.hash(isDark, page, base, shade, glint);
}
