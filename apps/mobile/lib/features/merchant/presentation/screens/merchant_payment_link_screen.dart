import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/merchant/presentation/controllers/merchant_payment_link_controller.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/merchant_flow_scaffold.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/merchant_glass_button.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_formatters.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/screens/payment/widgets/copyable_address.dart';
import 'package:mooze_mobile/features/pix/receive_pix/presentation/screens/payment/widgets/qr_code_display.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows the payment link of a sale, as the QR Code flow shows its QR Code.
///
/// The customer scans the QR Code of the link, or the merchant shares the
/// link or opens it in the browser. Back returns to the charge screen.
/// "Concluir venda" ends the sale.
class MerchantPaymentLinkScreen extends StatefulWidget {
  final PixPaymentLink link;
  final MerchantPaymentLinkRequest request;

  const MerchantPaymentLinkScreen({
    super.key,
    required this.link,
    required this.request,
  });

  /// Opens the screen. Returns true when the merchant ends the sale.
  static Future<bool> open(
    BuildContext context, {
    required PixPaymentLink link,
    required MerchantPaymentLinkRequest request,
  }) async {
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MerchantPaymentLinkScreen(link: link, request: request),
      ),
    );
    return done ?? false;
  }

  @override
  State<MerchantPaymentLinkScreen> createState() =>
      _MerchantPaymentLinkScreenState();
}

// When the link was just created, the scene of the QR code covers this
// screen as it opens, and fades away to uncover it: see
// `PixQrLoadingOverlay`.
class _MerchantPaymentLinkScreenState extends State<MerchantPaymentLinkScreen> {
  Future<void> _share() async {
    final t = AppLocalizations.of(context);
    await SharePlus.instance.share(
      ShareParams(
        text: t.merchant_payment_link_share_message(
          formatBrlCents(widget.request.amountInCents),
          widget.link.url,
        ),
      ),
    );
  }

  /// Opens the link in the browser, as the settings screens open URLs.
  Future<void> _openInBrowser() async {
    final t = AppLocalizations.of(context);
    try {
      final uri = Uri.parse(widget.link.url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        final fallback = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (!fallback && mounted) {
          AppSnackBar.error(context, t.merchant_payment_link_open_failed);
        }
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(context, t.merchant_payment_link_open_failed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return MerchantFlowScaffold(
      title: t.merchant_payment_method_link_title,
      amountInCents: widget.request.amountInCents,
      amountCaption: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          MerchantHeaderChip(
            icon: Icons.account_balance_wallet_outlined,
            label: t.merchant_payment_receive_in(widget.request.asset.ticker),
          ),
          if (widget.link.singleUse)
            MerchantHeaderChip(
              icon: Icons.looks_one_outlined,
              label: t.pix_hub_link_single_use,
            ),
        ],
      ),
      // Sharing is the main action. Ending the sale is a quieter text
      // button, so a stray tap does not end a sale before the payment.
      bottomAction: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(text: t.merchant_payment_link_share, onPressed: _share),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: context.colors.textPrimary,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Text(
              t.merchant_payment_link_done,
              style: context.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      children: [
        PixQrCodeDisplay(
          pixQrData: widget.link.url,
          boxConstraints: const BoxConstraints(),
          semanticLabel: t.merchant_payment_method_link_title,
        ),
        const SizedBox(height: 16),
        Text(
          t.merchant_payment_link_scan_hint,
          textAlign: TextAlign.center,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        CopyableAddress(
          pixKey: widget.link.url,
          label: t.pix_hub_link_url_label,
          icon: PixIcons.link,
          // The analytics schema has no payment-link event.
          trackCopy: false,
        ),
        const SizedBox(height: 12),
        MerchantGlassButton(
          label: t.merchant_payment_link_open,
          icon: PixIcons.externalLink,
          onPressed: _openInBrowser,
        ),
      ],
    );
  }
}
