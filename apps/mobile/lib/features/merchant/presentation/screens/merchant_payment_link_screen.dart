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
import 'package:mooze_mobile/themes/motion.dart';
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

  /// Plays the reveal that continues the loading overlay of the charge
  /// screen. Turn it off when the screen opens without that overlay.
  final bool playReveal;

  const MerchantPaymentLinkScreen({
    super.key,
    required this.link,
    required this.request,
    this.playReveal = true,
  });

  /// Opens the screen. Returns true when the merchant ends the sale.
  static Future<bool> open(
    BuildContext context, {
    required PixPaymentLink link,
    required MerchantPaymentLinkRequest request,
    bool playReveal = true,
  }) async {
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MerchantPaymentLinkScreen(
          link: link,
          request: request,
          playReveal: playReveal,
        ),
      ),
    );
    return done ?? false;
  }

  @override
  State<MerchantPaymentLinkScreen> createState() =>
      _MerchantPaymentLinkScreenState();
}

class _MerchantPaymentLinkScreenState extends State<MerchantPaymentLinkScreen>
    with SingleTickerProviderStateMixin {
  // Created in initState, never lazily: dispose must not create a ticker.
  late final AnimationController _revealController;
  late final Animation<double> _revealAnimation;
  OverlayEntry? _revealEntry;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _revealAnimation = Tween<double>(begin: 3.0, end: 0.0).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.easeInOutCubic),
    );
    if (widget.playReveal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // With reduced motion, the screen shows at once, without the
        // shrinking circle.
        if (!mounted || Motion.isReduced(context)) return;
        _showReveal();
        _revealController.forward().then((_) => _hideReveal());
      });
    }
  }

  @override
  void dispose() {
    _hideReveal();
    _revealController.dispose();
    super.dispose();
  }

  /// The shrinking circle of `PixPaymentScreen`. It starts over the full
  /// pink overlay of the charge screen and uncovers this screen.
  void _showReveal() {
    if (_revealEntry != null) return;
    _revealEntry = OverlayEntry(
      builder: (context) => AnimatedBuilder(
        animation: _revealController,
        builder: (context, child) {
          final size = MediaQuery.of(context).size;
          final value = _revealAnimation.value;
          final primary = context.colors.primaryColor;
          return IgnorePointer(
            child: Stack(
              children: [
                Positioned(
                  left: -size.width * 1.2,
                  bottom: -size.height * 0.3,
                  child: Container(
                    width: size.width * value * 1.2,
                    height: size.width * value * 1.2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: value / 3.0,
                    child: ColoredBox(color: primary),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    Overlay.of(context).insert(_revealEntry!);
  }

  void _hideReveal() {
    _revealEntry?.remove();
    _revealEntry = null;
  }

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
