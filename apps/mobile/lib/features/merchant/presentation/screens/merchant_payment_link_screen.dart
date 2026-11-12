import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/merchant/presentation/controllers/merchant_payment_link_controller.dart';
import 'package:mooze_mobile/features/merchant/presentation/widgets/merchant_flow_scaffold.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_formatters.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_qr_panel.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/detail/tx_meta_panel.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/detail_row.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/in_card_action_button.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows the payment link of a sale, as the QR Code flow shows its QR Code.
///
/// The customer scans the QR Code of the link, which always shows. Below
/// it, one panel holds the address of the link with copy, the share, and
/// the browser, as the link details of the Pix hub do. Back returns to the
/// charge screen. "Concluir venda", the only bottom action, ends the sale.
class MerchantPaymentLinkScreen extends StatefulWidget {
  final PixPaymentLink link;
  final MerchantPaymentLinkRequest request;

  const MerchantPaymentLinkScreen({
    super.key,
    required this.link,
    required this.request,
    this.debugLaunchUrl,
  });

  /// Stands in for [launchUrl], which needs a device with a browser.
  @visibleForTesting
  final Future<bool> Function(Uri url, {LaunchMode mode})? debugLaunchUrl;

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
  /// Side of the QR Code, small enough for the panel of the link to fit
  /// above the bottom button. It is the smallest side of the receive
  /// screen of the wallet, still easy to scan from another phone.
  static const double _qrSize = 160;

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
    final launch = widget.debugLaunchUrl ?? launchUrl;
    try {
      final uri = Uri.parse(widget.link.url);
      final launched = await launch(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        final fallback = await launch(uri, mode: LaunchMode.platformDefault);
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
      // The actions sit in the panel, so the bottom keeps only the end of
      // the sale. It is outlined, not filled: it does not look like the
      // next step of the payment, and a stray tap is less likely before
      // the customer pays.
      bottomAction: SecondaryButton(
        text: t.merchant_payment_link_done,
        onPressed: () => Navigator.of(context).pop(true),
      ),
      // The code, the address and the actions fit a phone above the bottom
      // button: the merchant shows the screen to the customer, and nothing
      // should hide under a scroll.
      children: [
        PixQrPanel(
          data: widget.link.url,
          size: _qrSize,
          semanticLabel: t.merchant_payment_method_link_title,
        ),
        const SizedBox(height: 12),
        Text(
          t.merchant_payment_link_scan_hint,
          textAlign: TextAlign.center,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        TxMetaPanel(
          cells: const [],
          ids: [
            DetailRow(
              label: t.pix_hub_link_url_label,
              value: shortLinkAddress(widget.link.url),
              copyable: true,
              copyValue: widget.link.url,
            ),
          ],
          links: [
            InCardActionButton(
              label: t.merchant_payment_link_share,
              subtitle: t.merchant_payment_link_share_subtitle,
              icon: Icons.ios_share_rounded,
              onPressed: _share,
            ),
            InCardActionButton(
              label: t.merchant_payment_link_open,
              subtitle: t.merchant_payment_link_open_subtitle,
              icon: Icons.language_rounded,
              onPressed: _openInBrowser,
            ),
          ],
        ),
      ],
    );
  }
}
