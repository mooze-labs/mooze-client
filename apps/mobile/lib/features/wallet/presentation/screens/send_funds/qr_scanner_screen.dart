import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets/qr_scanner_view.dart';
import '../../providers/send_funds/payment_request_applier.dart';
import '../../providers/send_funds/qr_validation_service.dart';
import 'package:mooze_mobile/shared/widgets.dart';

/// Camera step of the send flow.
///
/// [QrScannerView] draws the camera and its chrome. This screen checks the
/// code, applies a valid payment request to the send flow, and closes.
class QRCodeScannerScreen extends ConsumerStatefulWidget {
  const QRCodeScannerScreen({super.key});

  @override
  ConsumerState<QRCodeScannerScreen> createState() =>
      _QRCodeScannerScreenState();
}

class _QRCodeScannerScreenState extends ConsumerState<QRCodeScannerScreen> {
  bool isScanning = true;

  void _onCode(String scannedValue) {
    if (!isScanning) return;
    setState(() {
      isScanning = false;
    });

    HapticFeedback.mediumImpact();

    _processScannedData(scannedValue);
  }

  void _processScannedData(String data) {
    final validationResult = QrValidationService.validateQrData(data);

    if (!validationResult.isValid) {
      setState(() {
        isScanning = false;
      });

      AppSnackBar.error(context, validationResult.localize(context));

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            isScanning = true;
          });
        }
      });

      return;
    }

    PaymentRequestApplier.apply(ref, validationResult.cleanedData ?? data);

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return QrScannerView(
      title: t.wallet_send_address_scan_qr,
      hint: t.qr_scanner_position_hint,
      detail: t.qr_scanner_supported_networks,
      found: !isScanning,
      onCode: _onCode,
    );
  }
}
