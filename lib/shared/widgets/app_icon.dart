import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A thin, reusable wrapper around [SvgPicture.asset].
///
/// SVG files in this project carry their own embedded colours that are
/// designed to have adequate contrast in both light and dark themes.
/// [AppIcon] renders them as-is by default.
///
/// Pass an explicit [color] when you need to tint or override the SVG's
/// own colours (e.g. to match a specific semantic role). The colour is
/// applied via [BlendMode.srcIn], replacing all SVG colours uniformly.
/// Pass [Colors.transparent] explicitly to force the SVG's raw colours
/// even when a parent widget might otherwise supply a tint.
///
/// ```dart
/// // Automatic — SVG renders its own embedded colours:
/// AppIcon(path: 'assets/icons/menu/settings/theme.svg')
///
/// // Explicit tint override:
/// AppIcon(
///   path: 'assets/icons/menu/settings/theme.svg',
///   color: context.appColors.menuIconColor,
/// )
/// ```
class AppIcon extends StatelessWidget {
  const AppIcon({
    super.key,
    required this.path,
    this.size = 20,
    this.color,
  });

  /// Asset path for the SVG file.
  final String path;

  /// Rendered width and height in logical pixels. Defaults to `20`.
  final double size;

  /// Optional colour override applied via [BlendMode.srcIn].
  ///
  /// When `null` (default) the SVG is rendered with its own embedded colours.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      path,
      width: size,
      height: size,
      colorFilter:
          color != null
              ? ColorFilter.mode(color!, BlendMode.srcIn)
              : null,
    );
  }
}
