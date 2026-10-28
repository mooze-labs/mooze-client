import 'package:flutter/material.dart';
import 'package:mooze_mobile/themes/app_surfaces.dart';
import 'package:mooze_mobile/themes/motion.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

/// A Pix QR code on a white tile.
///
/// The tile stays white in both themes: banking apps read dark modules on a
/// light ground most reliably. The tile floats on the glass shadow, so it
/// belongs to the same family as the glass panels around it.
///
/// The code fades and scales in once when it appears, over
/// [Motion.durationEmphasis]. With reduced motion it appears at once.
class PixQrPanel extends StatefulWidget {
  const PixQrPanel({
    super.key,
    required this.data,
    this.size = defaultSize,
    this.semanticLabel,
  });

  /// Side of the code, without the white margin.
  static const double defaultSize = 220;

  /// The Pix code, usually a BR Code.
  final String data;
  final double size;

  /// Describes the code for screen readers, for example "Pix QR code".
  final String? semanticLabel;

  @override
  State<PixQrPanel> createState() => _PixQrPanelState();
}

class _PixQrPanelState extends State<PixQrPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.durationEmphasis,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isDismissed) {
      if (Motion.isReduced(context)) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Motion.curveEnter,
    );
    return Center(
      child: FadeTransition(
        opacity: curve,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(curve),
          child: Semantics(
            image: true,
            label: widget.semanticLabel,
            excludeSemantics: true,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: GlassStyle.of(context).shadows,
              ),
              child: SizedBox.square(
                dimension: widget.size,
                child: PrettyQrView.data(data: widget.data),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
