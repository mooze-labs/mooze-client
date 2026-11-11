import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mooze_mobile/features/setup/domain/seed_qr.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/app_snackbar.dart';
import 'package:mooze_mobile/shared/widgets/qr_scanner_view.dart';

import 'providers/seed_phrase_provider.dart';

/// Camera step of the import: reads the recovery phrase from a QR code and
/// fills the import screen with it.
class SeedQrScanScreen extends ConsumerStatefulWidget {
  const SeedQrScanScreen({super.key, this.debugPreview});

  /// Stands in for the camera preview, which needs a device.
  @visibleForTesting
  final Widget? debugPreview;

  @override
  ConsumerState<SeedQrScanScreen> createState() => _SeedQrScanScreenState();
}

class _SeedQrScanScreenState extends ConsumerState<SeedQrScanScreen> {
  static const _refusalPause = Duration(seconds: 4);

  bool _read = false;

  /// The camera reports a code in view continuously. While this runs, a
  /// refused code does not show its error again.
  Timer? _refusal;

  @override
  void dispose() {
    _refusal?.cancel();
    super.dispose();
  }

  void _onBarcode(Barcode barcode) {
    if (_read) return;
    final t = AppLocalizations.of(context);
    SeedQr.decode(text: barcode.rawValue, bytes: barcode.rawBytes).match(
      (error) => _refuse(switch (error) {
        SeedQrError.unsupported => t.seedqr_error_unsupported,
        SeedQrError.invalidPhrase => t.seedqr_error_invalid,
      }),
      (phrase) {
        if (!ref.read(seedPhraseProvider.notifier).importFullPhrase(phrase)) {
          _refuse(t.seedqr_error_invalid);
          return;
        }
        setState(() => _read = true);
        // The error of an earlier code must not stay on the import screen.
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        context.pop();
      },
    );
  }

  void _refuse(String message) {
    if (_refusal?.isActive ?? false) return;
    _refusal = Timer(_refusalPause, () {});
    AppSnackBar.error(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return QrScannerView(
      title: t.setup_import_scan_seedqr,
      hint: t.qr_scanner_position_hint,
      detail: t.seedqr_scan_detail,
      found: _read,
      // noDuplicates filters codes by their text, which a binary code such as
      // a CompactSeedQR may not have. [_refuse] throttles the repeats instead.
      detectionSpeed: DetectionSpeed.normal,
      onBarcode: _onBarcode,
      unavailableMessage: t.seedqr_scan_unavailable,
      debugPreview: widget.debugPreview,
    );
  }
}
