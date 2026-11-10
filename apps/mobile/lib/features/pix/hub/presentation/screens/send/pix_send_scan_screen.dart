import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mooze_mobile/features/pix/hub/domain/validation/pix_br_code.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_send_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_labels.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/qr_scanner_view.dart';

/// Camera step of the send flow.
///
/// It has the design of the wallet scan step, from [QrScannerView]. A
/// scanned code goes through the same local checks as a pasted one. When the
/// camera is unavailable, the screen points to Pix Copy and Paste.
class PixSendScanScreen extends ConsumerStatefulWidget {
  const PixSendScanScreen({super.key, this.debugPreview, this.debugController});

  /// Stands in for the camera preview, which needs a device.
  @visibleForTesting
  final Widget? debugPreview;

  /// Camera of the screen, so a test can report a camera error.
  @visibleForTesting
  final MobileScannerController? debugController;

  @override
  ConsumerState<PixSendScanScreen> createState() => _PixSendScanScreenState();
}

class _PixSendScanScreenState extends ConsumerState<PixSendScanScreen> {
  /// True while a code is being handled, so the screen starts one flow only.
  /// The scanner shows it as a found code.
  bool _handled = false;

  Future<void> _submitCode(String code, {required bool scanned}) async {
    // One code at a time: the camera reports continuously.
    if (_handled) return;
    setState(() => _handled = true);

    final t = AppLocalizations.of(context);
    final parsed = PixBrCodeParser.parse(code);

    if (!parsed.isStructurallyValid) {
      setState(() => _handled = false);
      AppSnackBar.error(context, pixBrCodeErrorMessage(t, parsed.error!));
      return;
    }

    final failure = ref
        .read(pixSendControllerProvider.notifier)
        .startFromCode(code, scanned: scanned);
    if (failure != null) {
      setState(() => _handled = false);
      AppSnackBar.error(context, pixHubFailureMessage(t, failure));
      return;
    }

    // The amount step also asks for the tax ID of the key owner, so a code
    // with a fixed amount passes through it too.
    await context.push('/pix/send/amount');
    // Back on this screen: accept the next code.
    if (mounted) setState(() => _handled = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return QrScannerView(
      title: t.pix_hub_action_pay_qr,
      hint: t.qr_scanner_position_hint,
      detail: t.pix_hub_send_method_qr_description,
      found: _handled,
      // The camera reports a code in view again and again. A code that was
      // refused stays refused until another code shows up.
      detectionSpeed: DetectionSpeed.noDuplicates,
      onCode: (code) => _submitCode(code, scanned: true),
      unavailableMessage: t.pix_hub_scan_unavailable_body,
      // The step replaces the camera, so back still returns to the hub.
      unavailableAction: PrimaryButton(
        text: t.pix_hub_action_copy_paste,
        onPressed: () => context.pushReplacement('/pix/send/code'),
      ),
      controller: widget.debugController,
      debugPreview: widget.debugPreview,
    );
  }
}
