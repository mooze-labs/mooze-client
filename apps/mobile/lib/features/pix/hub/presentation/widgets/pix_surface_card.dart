import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/widgets/glass/liquid_glass.dart';

/// Glass panel that groups related rows.
///
/// It is a [GlassPanel]: the Liquid Glass of the main screens, without a
/// backdrop blur, because it scrolls over the fixed screen backdrop. The hub
/// uses a single panel level, so the screens stay free of nested boxes.
class PixSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const PixSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(4),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GlassPanel(padding: padding, child: child),
    );
  }
}
