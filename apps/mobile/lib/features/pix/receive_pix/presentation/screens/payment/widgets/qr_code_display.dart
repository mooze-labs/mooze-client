import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_qr_panel.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

/// The QR code of a Pix charge or a payment link.
///
/// The tile comes from [PixQrPanel]: a white tile on the glass shadow. The
/// code keeps [PixQrPanel.defaultSize] and shrinks only when the available
/// width is smaller, so the tile never overflows a narrow screen.
class PixQrCodeDisplay extends StatelessWidget {
  /// Kept for the callers. The tile measures its own width.
  final BoxConstraints boxConstraints;

  /// The data of the code. The tile shows it without changes.
  final String pixQrData;

  /// Describes the code for screen readers. Defaults to "Pix QR Code".
  final String? semanticLabel;

  const PixQrCodeDisplay({
    super.key,
    required this.pixQrData,
    required this.boxConstraints,
    this.semanticLabel,
  });

  /// White margin of the tile on each side.
  static const double _tilePadding = 16;

  @override
  Widget build(BuildContext context) {
    final label =
        semanticLabel ??
        AppLocalizations.of(context).merchant_payment_method_qr_title;
    return LayoutBuilder(
      builder: (context, constraints) {
        var size = PixQrPanel.defaultSize;
        if (constraints.hasBoundedWidth) {
          size = math.min(size, constraints.maxWidth - _tilePadding * 2);
        }
        return PixQrPanel(
          data: pixQrData,
          size: math.max(size, 0),
          semanticLabel: label,
        );
      },
    );
  }
}
