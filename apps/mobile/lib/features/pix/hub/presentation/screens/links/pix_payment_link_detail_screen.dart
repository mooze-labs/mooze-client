import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/providers/pix_hub_providers.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/screens/links/pix_payment_link_revoke.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_formatters.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_hub_labels.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_icon_well.dart';
import 'package:mooze_mobile/features/pix/hub/presentation/widgets/pix_qr_sheet.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/detail/tx_detail_scaffold.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/detail/tx_meta_panel.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/detail/tx_status_panel.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/detail_row.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/hero_amount.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/in_card_action_button.dart';
import 'package:mooze_mobile/features/transaction_history/presentation/widgets/info_banner.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/prices/store/locale_string_provider.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:mooze_mobile/utils/formatters.dart';
import 'package:share_plus/share_plus.dart';

/// Details of one payment link, laid out as the details of a wallet
/// transaction.
///
/// The hero holds the coin of the asset that the link pays, with a link
/// badge, the identification that says which charge this is, and the
/// amount. The status panel follows, with the creation date and the track
/// of the link: created, waiting, paid. A link that takes no more payments
/// says why in a note. One glass panel holds the metadata: the asset and
/// the usage, the address with copy, and the actions: share the link, or
/// show its QR Code in a floating sheet.
///
/// Revoke is destructive, so it lives in the menu of the bar and asks for a
/// confirmation. A paid, expired, or revoked link has no address, actions,
/// or menu: they would only lead the payer to a dead page.
///
/// The screen follows the link in the list, so a revoke turns the status
/// and the actions here at once.
class PixPaymentLinkDetailScreen extends ConsumerWidget {
  /// The link as the previous screen saw it. It shows until the list has
  /// the link, for example right after the link was created.
  final PixPaymentLink link;

  const PixPaymentLinkDetailScreen({super.key, required this.link});

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
    final active = link.isActive;
    final asset = link.asset;
    final notice = _inactiveNotice(context, link.status);

    return TxDetailScaffold(
      title: t.pix_hub_link_detail_title,
      entranceKey: 'payment-link-${link.id}',
      actions: [
        if (active)
          _LinkMenu(
            onRevoke: () => confirmAndRevokePaymentLink(context, ref, link),
          ),
      ],
      hero: Column(
        children: [
          if (asset != null) ...[
            HeroAssetIcon(asset: asset, glyph: Icons.link_rounded),
            const SizedBox(height: 14),
          ],
          if (link.reference.isNotEmpty) ...[
            Text(
              link.reference,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
          ],
          _HeroAmount(
            amountInCents: link.amountInCents,
            paid: link.status == PixPaymentLinkStatus.paid,
          ),
        ],
      ),
      sections: [
        _status(context, ref, link),
        if (notice != null)
          Padding(padding: const EdgeInsets.only(top: 12), child: notice),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: TxMetaPanel(
            cells: [
              if (asset != null)
                MetaCell(
                  t.pix_hub_link_asset_label,
                  asset.name,
                  leading: SvgPicture.asset(
                    asset.iconPath,
                    width: 18,
                    height: 18,
                  ),
                ),
              MetaCell(
                t.pix_hub_link_usage_label,
                link.singleUse
                    ? t.pix_hub_link_single_use
                    : t.pix_hub_link_reusable,
              ),
              if (link.paidAt case final paidAt?)
                MetaCell(
                  t.pix_hub_link_paid_at,
                  _dateTime(context, ref, paidAt),
                  wide: true,
                ),
            ],
            ids: [
              if (active)
                DetailRow(
                  label: t.pix_hub_link_url_label,
                  value: _shortUrl(link.url),
                  copyable: true,
                  copyValue: link.url,
                ),
            ],
            links: [
              if (active) ...[
                InCardActionButton(
                  label: t.pix_hub_link_share_action,
                  subtitle: t.pix_hub_link_share_action_subtitle,
                  icon: Icons.ios_share_rounded,
                  onPressed: () => _share(context, link),
                ),
                InCardActionButton(
                  label: t.pix_hub_link_qr_action,
                  subtitle: t.pix_hub_link_qr_action_subtitle,
                  icon: Icons.qr_code_2_rounded,
                  // The QR Code opens in the app, not outside it.
                  trailingIcon: Icons.chevron_right_rounded,
                  onPressed: () => _showQrCode(context, link),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// The status panel: the status, the creation date, and the track of the
  /// link, as the status of a transaction.
  Widget _status(BuildContext context, WidgetRef ref, PixPaymentLink link) {
    final t = AppLocalizations.of(context);
    final created = TxStep(t.pix_hub_link_step_created, TxStepState.done);
    final paid = t.pix_hub_link_status_paid;
    final (icon, tone, steps) = switch (link.status) {
      PixPaymentLinkStatus.pending => (
        Icons.schedule_rounded,
        PixTone.warning,
        [
          created,
          TxStep(t.pix_hub_link_step_waiting, TxStepState.active),
          TxStep(paid, TxStepState.upcoming),
        ],
      ),
      PixPaymentLinkStatus.paid => (
        Icons.check_rounded,
        PixTone.positive,
        [
          created,
          TxStep(t.pix_hub_link_step_waiting, TxStepState.done),
          TxStep(paid, TxStepState.done),
        ],
      ),
      // The link stopped where it was: the track shows the step that
      // ended it, and the payment it never got.
      PixPaymentLinkStatus.expired || PixPaymentLinkStatus.revoked => (
        Icons.link_off_rounded,
        PixTone.neutral,
        [
          created,
          TxStep(pixPaymentLinkStatusLabel(t, link.status), TxStepState.failed),
          TxStep(paid, TxStepState.upcoming),
        ],
      ),
    };
    return TxStatusPanel(
      icon: icon,
      title: pixPaymentLinkStatusLabel(t, link.status),
      // An expired or a revoked link is gray, as its chip in the list.
      color: tone == PixTone.neutral
          ? context.colors.textSecondary
          : pixToneColor(context, tone),
      details: [_dateTime(context, ref, link.createdAt)],
      steps: steps,
    );
  }

  /// Why a link takes no more payments, or null while it takes them.
  Widget? _inactiveNotice(BuildContext context, PixPaymentLinkStatus status) {
    final t = AppLocalizations.of(context);
    return switch (status) {
      PixPaymentLinkStatus.pending => null,
      PixPaymentLinkStatus.paid => InfoBanner(
        icon: Icons.check_circle_outline_rounded,
        color: context.colors.positiveColor,
        message: t.pix_hub_link_inactive_paid,
      ),
      PixPaymentLinkStatus.expired => InfoBanner(
        icon: Icons.info_outline_rounded,
        color: context.colors.textSecondary,
        message: t.pix_hub_link_inactive_expired,
      ),
      PixPaymentLinkStatus.revoked => InfoBanner(
        icon: Icons.info_outline_rounded,
        color: context.colors.textSecondary,
        message: t.pix_hub_link_inactive_revoked,
      ),
    };
  }

  /// A date and time as the transaction details write them, for example
  /// "11 de nov. de 2026 às 14:32".
  static String _dateTime(BuildContext context, WidgetRef ref, DateTime at) {
    final locale = ref.watch(localeStringProvider);
    final use24h = MediaQuery.alwaysUse24HourFormatOf(context);
    final date = DateFormat.yMMMd(locale).format(at);
    final time = (use24h ? DateFormat.Hm(locale) : DateFormat.jm(locale))
        .format(at);
    return AppLocalizations.of(context).tx_detail_datetime(date, time);
  }

  /// The address of the link, short enough for the value column: the ends
  /// of its token, as a transaction ID shows its ends. The copy takes the
  /// whole address.
  static String _shortUrl(String url) {
    final token = Uri.tryParse(url)?.pathSegments.lastOrNull;
    if (token == null || token.isEmpty) return truncateHashId(url);
    return truncateHashId(token);
  }

  /// Shows the QR Code of the link in a floating sheet, for a payer in
  /// person.
  void _showQrCode(BuildContext context, PixPaymentLink link) {
    final t = AppLocalizations.of(context);
    final cents = link.amountInCents;
    showPixQrSheet(
      context,
      data: link.url,
      subtitle: cents == null
          ? t.pix_hub_link_open_amount
          : formatBrlCents(cents),
      caption: t.pix_hub_link_qr_caption,
    );
  }
}

/// The amount of the link, at the size of a transaction amount.
///
/// The currency symbol is smaller and muted, so the eye goes to the digits.
/// A paid link shows the amount it brought in, with a plus sign and the
/// positive color, as a received transaction. A long amount or a large
/// text size scales the line down. It never wraps.
class _HeroAmount extends StatelessWidget {
  /// Amount in BRL cents, or null when the payer informs the amount.
  final int? amountInCents;

  final bool paid;

  const _HeroAmount({required this.amountInCents, required this.paid});

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
    // The sign carries the direction, so it never depends on color.
    final sign = paid ? '+ ' : '';

    return Semantics(
      label: '$sign$formatted'.trim(),
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text.rich(
          TextSpan(
            children: [
              if (sign.isNotEmpty) TextSpan(text: sign),
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
          style: context.textTheme.displaySmall?.copyWith(
            color: paid
                ? context.colors.positiveColor
                : context.colors.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
            height: 1.1,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

/// The menu of the bar, with the revoke of a link that takes payments.
///
/// The revoke is destructive, so its icon and its text have the negative
/// color, and it still asks for a confirmation.
class _LinkMenu extends StatelessWidget {
  final VoidCallback onRevoke;

  const _LinkMenu({required this.onRevoke});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final negative = context.colors.negativeColor;
    return PopupMenuButton<VoidCallback>(
      tooltip: t.pix_hub_link_actions,
      icon: Icon(Icons.more_vert_rounded, color: context.colors.textPrimary),
      onSelected: (action) => action(),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: onRevoke,
          child: Row(
            children: [
              PixIcon(PixIcons.delete, size: 20, color: negative),
              const SizedBox(width: 12),
              Text(t.pix_hub_link_revoke, style: TextStyle(color: negative)),
            ],
          ),
        ),
      ],
    );
  }
}
