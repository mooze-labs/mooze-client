import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';

/// A status icon in a circle of its tint, for the leading slot of a
/// `GlassSheetHeader` or a `StatusBanner`: a warning, an error, or the
/// offline state.
class GlassSheetBadge extends StatelessWidget {
  const GlassSheetBadge({super.key, required this.icon, required this.color});

  final PixIconData icon;

  /// The tone of the status, for example the warning or the error color.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.14),
      ),
      child: PixIcon(icon, size: 20, color: color),
    );
  }
}
