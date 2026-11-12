import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_hub_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/links/pix_payment_link_revoke.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/links/pix_payment_links_screen.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_copy_field.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_formatters.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_qr_panel.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_screen_scaffold.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_summary_card.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_surface_card.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:share_plus/share_plus.dart';

/// Details of one payment link, with the actions to copy, to share and to
/// turn it off.
///
/// The amount is the hero. The identification, which says which charge
/// this is, sits below it, then the status chip. The QR Code of the link
/// address sits on its white tile, and the address is a copy field. Share
/// is the main action. A link that still takes payments can be revoked
/// below it.
///
/// A paid, expired, or revoked link takes no more payments: its QR Code or
/// address would only lead the payer to a dead page. The screen then says
/// why in their place, keeps the details, and has no actions.
///
/// The screen follows the link in the list, so a revoke turns the status
/// and the actions here at once.
class PixPaymentLinkDetailScreen extends ConsumerWidget {
  /// The link as the previous screen saw it. It shows until the list has
  /// the link, for example right after the link was created.
  final PixPaymentLink link;

  const PixPaymentLinkDetailScreen({super.key, required this.link});

  /// Side of the QR Code, as on the link screen of the merchant mode. With
  /// the identification above it, the address still shows on the first
  /// screen of a phone.
  static const double _qrSize = 184;

  /// Shares the link with the amount, as the merchant mode does. A link
  /// with an open amount goes alone: the payer chooses the amount.
  Future<void> _share(BuildContext context, PixPaymentLink link) async {
    final t = AppLocalizations.of(context);
    final cents = link.amountInCents;
    await SharePlus.instance.share(
      ShareParams(
        text: cents == null
            ? t.pix_hub_link_share_message(link.url)
            : t.pix_hub_link_share_message_amount(
                formatBrlCents(cents),
                link.url,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final link =
        ref.watch(
          pixHubPaymentLinksProvider.select(
            (links) => links.valueOrNull
                ?.where((l) => l.id == this.link.id)
                .firstOrNull,
          ),
        ) ??
        this.link;
    final asset = link.asset;
    final active = link.isActive;

    return PixScreenScaffold(
      title: t.pix_hub_link_detail_title,
      bottomAction: !active
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PrimaryButton(
                  text: t.pix_hub_share,
                  onPressed: () => _share(context, link),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () =>
                      confirmAndRevokePaymentLink(context, ref, link),
                  style: TextButton.styleFrom(
                    foregroundColor: context.colors.negativeColor,
                    minimumSize: const Size(64, 48),
                  ),
                  child: Text(t.pix_hub_link_revoke),
                ),
              ],
            ),
      children: [
        Center(child: _HeroAmount(amountInCents: link.amountInCents)),
        if (link.reference.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            link.reference,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.titleMedium?.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Center(child: PixPaymentLinkStatusChip(status: link.status)),
        const SizedBox(height: 24),
        if (active) ...[
          PixQrPanel(
            data: link.url,
            size: _qrSize,
            semanticLabel: t.pix_hub_method_qr,
          ),
          const SizedBox(height: 28),
          PixCopyField(
            label: t.pix_hub_link_url_label,
            value: link.url,
            icon: PixIcons.link,
          ),
        ] else
          _InactiveNotice(status: link.status),
        const SizedBox(height: 24),
        PixSummaryCard(
          entries: [
            if (asset != null)
              PixSummaryEntry(t.pix_hub_link_asset_label, asset.ticker),
            PixSummaryEntry(
              t.pix_hub_link_usage_label,
              link.singleUse
                  ? t.pix_hub_link_single_use
                  : t.pix_hub_link_reusable,
            ),
            PixSummaryEntry(
              t.pix_hub_summary_created_at,
              formatPixDateTime(link.createdAt),
            ),
            if (link.paidAt != null)
              PixSummaryEntry(
                t.pix_hub_link_paid_at,
                formatPixDateTime(link.paidAt!),
              ),
          ],
        ),
        if (active) ...[
          const SizedBox(height: 14),
          _Note(text: t.pix_hub_link_disclaimer),
        ],
      ],
    );
  }
}

/// Says why a link takes no more payments, where its QR Code was.
///
/// The icon well and the text carry the state, never the color alone. A
/// paid link has the positive tone. An expired or a revoked one is neutral,
/// with the broken link of its status chip.
class _InactiveNotice extends StatelessWidget {
  final PixPaymentLinkStatus status;

  const _InactiveNotice({required this.status});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final (icon, tone, text) = switch (status) {
      PixPaymentLinkStatus.paid => (
        PixIcons.check,
        PixTone.positive,
        t.pix_hub_link_inactive_paid,
      ),
      PixPaymentLinkStatus.expired => (
        PixIcons.linkOff,
        PixTone.neutral,
        t.pix_hub_link_inactive_expired,
      ),
      PixPaymentLinkStatus.revoked => (
        PixIcons.linkOff,
        PixTone.neutral,
        t.pix_hub_link_inactive_revoked,
      ),
      // A pending link shows its QR Code instead.
      PixPaymentLinkStatus.pending => (PixIcons.clock, PixTone.warning, ''),
    };
    return PixSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          PixIconWell(icon: icon, tone: tone),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The amount of the link as the hero of the screen.
///
/// The digits are large and use tabular figures. The currency symbol is
/// smaller and muted, so the eye goes to the digits. A long amount or a
/// large text size scales the line down. It never wraps.
class _HeroAmount extends StatelessWidget {
  /// Amount in BRL cents, or null when the payer informs the amount.
  final int? amountInCents;

  const _HeroAmount({required this.amountInCents});

  @override
  Widget build(BuildContext context) {
    final cents = amountInCents;
    if (cents == null) {
      return Text(
        AppLocalizations.of(context).pix_hub_link_open_amount,
        textAlign: TextAlign.center,
        style: context.textTheme.headlineSmall?.copyWith(
          color: context.colors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    final formatted = formatBrlCents(cents);
    // The format puts a space between the symbol and the digits.
    final split = formatted.indexOf(RegExp(r'\s'));
    final symbol = split < 0 ? '' : formatted.substring(0, split);
    final digits = split < 0 ? formatted : formatted.substring(split + 1);

    return Semantics(
      label: formatted,
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text.rich(
          TextSpan(
            children: [
              if (symbol.isNotEmpty)
                TextSpan(
                  text: '$symbol ',
                  style: context.textTheme.titleLarge?.copyWith(
                    color: context.colors.textSecondary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              TextSpan(text: digits),
            ],
          ),
          maxLines: 1,
          style: context.textTheme.headlineLarge?.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

/// A short explanation at the end of the screen, with an info icon.
class _Note extends StatelessWidget {
  final String text;

  const _Note({required this.text});

  @override
  Widget build(BuildContext context) {
    // Secondary, not tertiary: the tertiary gray fails 4.5:1 on the light
    // page background.
    final color = context.colors.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: PixIcon(PixIcons.info, size: 15, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: context.textTheme.bodySmall?.copyWith(
                color: color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
